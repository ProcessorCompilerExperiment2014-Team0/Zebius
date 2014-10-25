(defparameter field-name #(a b c d))
(defparameter instruction-set
  '("0000nnnn00000000"
    "0000nnnn00000001"
    "1110nnnniiiiiiii"
    "1001nnnndddddddd"
    "0110nnnnmmmm0011"
    "0010nnnnmmmm0010"
    "0110nnnnmmmm0010"
    "0000nnnn00101010"
    "0011nnnnmmmm1100"
    "0111nnnniiiiiiii"
    "0011nnnnmmmm0000"
    "0011nnnnmmmm0111"
    "0011nnnnmmmm1000"
    "0010nnnnmmmm1001"
    "0110nnnnmmmm0111"
    "0010nnnnmmmm1011"
    "0010nnnnmmmm1010"
    "0100nnnnmmmm1101"
    "10001011dddddddd"
    "10001001dddddddd"
    "1010dddddddddddd"
    "0100nnnn00101011"
    "0100nnnn00001011"
    "0000000000001011"))

(defun split (inst)
    (list (subseq inst 0 4) (subseq inst 4 8) (subseq inst 8 12) (subseq inst 12 16)))

(defun literalp (i)
  (every (lambda (x) (or (char= x #\0) (char= x #\1))) i))

(defun varp (i)
  (and (not (literalp i)) (intern (string-upcase (subseq i 0 1)))))

(defun tokenize (inst)
  (mapcar (lambda (i) (if (literalp i)
			  i
			  (varp i)))
	  (split inst)))

(defun parse% (sym tokens c cs match bind)
  (if (or (null tokens)
	  (not (eq sym (car tokens))))
      (parse tokens c match `((,sym ,(reverse cs)) ,@bind))
      (parse% sym (cdr tokens) (1+ c) (cons c cs) match bind)))

(defun parse (tokens &optional (count 0) (match nil) (bind nil))
  (cond ((null tokens) (list (reverse match) (reverse bind)))
	((stringp (car tokens))
	 (parse (cdr tokens) (1+ count) `((,count ,(car tokens)) ,@match) bind))
	(t (parse% (car tokens) tokens count '() match bind))))

(defun singlep (l)
  (and (listp l) (null (cdr l))))

(defun converter (v)
  (case v
    (n 'to_integer)
    (m 'to_integer)
    (d nil)))

(defmacro aif (pred then &optional else)
  `(let ((it ,pred))
     (if it
	 ,then
	 ,else)))

(defun expand-rule-1 (var rule)
  (destructuring-bind (match bind) rule
    `((and ,@(mapcar (lambda (x)
		       `(= (of ,var ,(aref field-name (car x)))
			   ,(cadr x)))
		     match))
      ,@(mapcar (lambda (x)
		  (if (singlep (cadr x))
		      (destructuring-bind (v l) x
			`(set! ,v ,(aif (converter v)
					`(,it (of ,var ,(aref field-name (car l))))
					`(of ,var ,(aref field-name (car l))))))
		      (destructuring-bind (v l) x
			`(set! ,v (concat ,@(mapcar (lambda (x)
						      (aif (converter v)
							   `(,it (of ,var,(aref field-name x)))
							   `(of ,var ,(aref field-name x))))
						    l))))))
		bind))))

(defun expand (var rules)
  `(cond ,@(mapcar (lambda (x) (expand-rule-1 var x))
		   rules)))

(defun interleave (ls ms)
  (iter (for l in ls)
	(for m in ms)
	(collect l)
	(collect m)))

(defparameter *primitive-emitter-table* (make-hash-table))

(defun primitive-emitter-p (name)
  (multiple-value-bind (var win) (gethash name *primitive-emitter-table*)
    (declare (ignorable var))
    win))

(defmacro defemitter (name arg &body body)
    (let ((emitter-name (intern (concatenate 'string "EMIT-" (symbol-name name)))))
      `(progn
	 (defun ,emitter-name ,arg
	   ,@body)
	 (setf (gethash ',name *primitive-emitter-table*) #',emitter-name))))


(defemitter of (body o)
  (destructuring-bind (struct f) body
    (assert (symbolp f))
    (format o "~a.~a" (emit-vhdl struct nil) (emit-vhdl f nil))))

(defemitter = (body o)
  (destructuring-bind (l r) body
    (format o "~a = ~a" (emit-vhdl l nil) (emit-vhdl r nil))))

(defemitter set! (body o)
  (destructuring-bind (var val) body
    (format o "~a := ~a;~%" (emit-vhdl var nil) (emit-vhdl val nil))))

(defemitter and (body o)
  (format o "~{~a~^ and ~}" (mapcar (lambda (x) (emit-vhdl x nil)) body)))

(defemitter concat (body o)
  (format o "~{~a~^ & ~}" (mapcar (lambda (x) (emit-vhdl x nil)) body)))

(defemitter cond (body o)
  (format o "if~{ ~a then~%~{~a~}~^elsif~}end if"
	  (interleave (mapcar #'(lambda (x)
				  (emit-vhdl (car x) nil))
			      body)
		      (mapcar #'(lambda (x)
				  (mapcar (lambda (y) (emit-vhdl y nil))
					  (cdr x)))
			      body))))

(defemitter call (body o)
  (destructuring-bind (fn &rest args) body
    (format o "~(~a~)(~{~a~^, ~})" fn (mapcar (lambda (x) (emit-vhdl x nil)) args))))

(defun emit-vhdl (sexp o)
  (cond ((symbolp sexp) (format o "~a" (string-downcase (symbol-name sexp))))
	((stringp sexp) (format o "~s" sexp))
	((numberp sexp) (format o "~a" sexp))
	((listp sexp)
	 (destructuring-bind (head &body body) sexp
	   (cond ((primitive-emitter-p head)
		  (funcall (gethash head *primitive-emitter-table*)
			   body o))
		 (t (emit-call sexp o)))))))
