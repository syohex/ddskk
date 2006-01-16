;;; skk-comp.el --- $BJd40$N$?$a$N%W%m%0%i%`(B

;; Copyright (C) 1988, 1989, 1990, 1991, 1992, 1993, 1994, 1995, 1996, 1997
;;               1999, 2000
;;   Masahiko Sato <masahiko@kuis.kyoto-u.ac.jp>

;; Author: Masahiko Sato <masahiko@kuis.kyoto-u.ac.jp>
;; Maintainer: SKK Development Team <skk@ring.gr.jp>
;; Version: $Id: skk-comp.el,v 1.55 2006/01/16 10:23:28 skk-cvs Exp $
;; Keywords: japanese, mule, input method
;; Last Modified: $Date: 2006/01/16 10:23:28 $

;; This file is part of Daredevil SKK.

;; Daredevil SKK is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2, or
;; (at your option) any later version.

;; Daredevil SKK is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with Daredevil SKK, see the file COPYING.  If not, write to
;; the Free Software Foundation Inc., 51 Franklin St, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; $B"&$5(B (TAB) -> $B"&$5$H$&(B (.) -> $B"&$5$$$H$&(B (,) -> $B"&$5$H$&(B(.) -> $B"&$5$$$H$&(B

;;; Code:

(eval-when-compile
  (require 'skk-macs)
  (require 'skk-vars))

;;;###autoload
(defun skk-comp-start-henkan (arg)
  "$B"&%b!<%I$GFI$_$NJd40$r9T$J$C$?8e!"JQ49$9$k!#(B
$B$=$l0J30$N%b!<%I$G$O%*%j%8%J%k$N%-!<%^%C%W$K3d$jIU$1$i$l$?%3%^%s%I$r%(%_%e%l!<(B
$B%H$9$k!#(B"
  (interactive "*P")
  (cond
   ((eq skk-henkan-mode 'on)
    (skk-comp-do (not (eq last-command 'skk-comp-do)))
    (skk-start-henkan arg))
   (t
    (skk-emulate-original-map arg))))

;;;###autoload
(defun skk-comp (first &optional silent)
  (setq this-command 'skk-comp-do)
  (skk-comp-do first silent))

;;;###autoload
(defun skk-comp-do (first &optional silent)
  ;; main completion engine.
  (let ((inhibit-quit t)
	;; skk-num $B$,(B require $B$5$l$F$J$$$H(B
	;; buffer-local $BCM$r2u$962$l$"$j!#(B
	skk-num-list
        tmp-key data
	c-word)
    (when first
      (setq skk-comp-search-done nil
	    skk-comp-stack nil
	    skk-comp-depth 0
	    skk-comp-prefix skk-prefix)
      ;;  key  \ use-prefix    nil	  kakutei-first	  non-nil	 # data
      ;; "$B$+(Bk"		     "$B$+(B"  , ""	   "$B$+(B"	 , "k"	  "$B$+(B", "k"	 #    t
      ;; "$B$+(Bn"		     "$B$+$s(B", ""	   "$B$+$s(B", ""	  "$B$+(B", "n"	 # non-t
      (setq tmp-key (buffer-substring-no-properties
		     skk-henkan-start-point (point)))
      ;; skk-kana-cleanup() $B$r8F$VA0$N(B key $B$r<hF@(B
      (unless (or skk-abbrev-mode
		  (memq skk-comp-use-prefix '(nil kakutei-first)))
	(save-match-data
	  (if (string-match "^\\([^a-z]*\\)[a-z]*$" tmp-key)
	      (setq skk-comp-key (match-string 1 tmp-key))
	    ;; $BAw$jL5$7$G8+=P$7$K%"%k%U%!%Y%C%H$r4^$`$h$&$JJQB'E*$J8uJd$O!"(B
	    ;; skk-echo $B$b9M$($k$H$^$H$b$JBP=h$,LLE]$J$N$G!"(B
	    ;; $B32$,L5$$HO0O$GE,Ev$K=hM}!#(B nil $B$+(B kakutei-first $B$r;H$C$F$b$i$&!#(B
	    (setq skk-comp-key tmp-key))))
      ;; prefix $B$KBP1~$9$k!V$+$J!W(Betc. $B$,$"$l$P(B non-t
      ;; $BI{:nMQ$rH<$J$&%k!<%k$,;XDj$5$l$F$$$k$+$b$7$l$J$$$N$G!"(B
      ;; $B%G!<%?$,$"$k$+$I$&$+$N%A%'%C%/$N$_$K;H$&!#(B
      (setq data
	    (skk-kana-cleanup 'force))
      (when (or skk-abbrev-mode
		(memq skk-comp-use-prefix '(nil kakutei-first)))
	(setq skk-comp-key (buffer-substring-no-properties
			    skk-henkan-start-point (point)))
	(unless (and skk-comp-use-prefix
		     (eq data t))
	  (setq skk-comp-prefix ""))))
    (cond
     ;; ($B2a5n$KC5:w:Q$_$NFI$_$r%"%/%;%9Cf(B)
     (skk-comp-search-done
      (if (= skk-comp-depth 0)
	  ;; circulate $B$J$i$P(B c-word = skk-comp-key $B$J$N$G(B c-word = nil
	  ;; non-circulate $B$J$i$P(B $B$3$l0J>e8uJd$,$J$$$N$G(B c-word = nil
	  (if skk-comp-circulate
	      (setq skk-comp-depth (length skk-comp-stack)))
	(setq skk-comp-depth (1- skk-comp-depth))
	(setq c-word (nth skk-comp-depth skk-comp-stack))))
     ;; ($B?75,$NFI$_$rC5:w(B)
     (t
      (setq c-word
	    (let ((word (skk-comp-get-candidate first)))
	      (while (member word skk-comp-stack)
		(setq word (skk-comp-get-candidate)))
	      word))
      (if c-word
	  ;; $B?75,$K8+$D$1$?$H$-$@$1(B push $B$9$k!#(B
	  (push c-word skk-comp-stack)
	(setq skk-comp-search-done t)
	(if skk-comp-circulate
	    (setq skk-comp-depth (length skk-comp-stack))))))
    (cond
     (c-word
      (delete-region skk-henkan-start-point (point))
      (insert c-word))
     (t
      ;; When skk-comp-circulate, return to the keyword.
      (when skk-comp-circulate
	(delete-region skk-henkan-start-point (point))
	(insert skk-comp-key))
      (unless silent
	(ding)
	(cond
	 ((and (string= skk-comp-key "")
	       (or (not skk-comp-use-prefix)
		   (string= skk-comp-prefix "")))
	  (skk-message "$B$3$l0J>e$NMzNr$O$"$j$^$;$s(B"
		       "No more words in history"))
	 (t
	  (if skk-japanese-message-and-error
	      (message "\"%s\" $B$GJd40$9$Y$-8+=P$78l$O(B%s$B$"$j$^$;$s(B"
		       (if skk-comp-use-prefix
			   (concat skk-comp-key skk-comp-prefix)
			 skk-comp-key)
		       (if first "" "$BB>$K(B"))
	    (message "No %scompletions for \"%s\""
		     (if first "" "more ")
		     (if skk-comp-use-prefix
			 (concat skk-comp-key skk-comp-prefix)
		       skk-comp-key))))))))))

(defun skk-comp-get-candidate (&optional first)
  (when first
    (setq skk-comp-first t
	  skk-current-completion-prog-list skk-completion-prog-list))
  (let (cand prog)
    (while (and (null cand)
		skk-current-completion-prog-list)
      (setq prog (car skk-current-completion-prog-list))
      (setq cand (eval prog)
	    skk-comp-first nil)
      (unless cand
	(setq skk-current-completion-prog-list
	      (cdr skk-current-completion-prog-list))
	(setq skk-comp-first t)))
    cand))

;; for test or backend use
;;;###autoload
(defun skk-comp-get-all-candidates (key prefix prog-list)
  (let ((skk-comp-key key)
	(skk-comp-prefix prefix)
	(skk-completion-prog-list prog-list)
	skk-current-completion-prog-list
	skk-comp-first
	cand ret)
    (setq ret (list (skk-comp-get-candidate 'first)))
    (while (setq cand (skk-comp-get-candidate))
      (unless (member cand ret)
	(setq ret (cons cand ret))))
    (nreverse ret)))

;;;###autoload
(defun skk-comp-from-jisyo (file)
  ;; skk-comp-prefix $B$O;H$o$J$$HG(B
  "SKK $B<-=q%U%)!<%^%C%H$N(B FILE $B$+$iJd408uJd$rF@$k!#(B"
  (let ((buffer (skk-get-jisyo-buffer file 'nomsg))
	(abbrev skk-abbrev-mode)
	(key skk-comp-key)
	(first skk-comp-first)
	word)
    (with-current-buffer buffer
      (when first
	(goto-char skk-okuri-nasi-min))
      ;; $B=>Mh$N5sF0$K9g$o$;$F$*$/$,!"3NDjMzNr$@$1$G$J$/(B
      ;; $B8D?M<-=q$b;H$($?$[$&$,$$$$$N$+$I$&$+(B
      (unless (string= key "")
	;; $BCf?H$r$4$C$=$j<h$j9~$b$&$+$H;W$C$?$1$I(B
	;; $B$H$j$"$($:MxMQ$9$k$3$H$K(B
	(skk-comp-search-current-buffer key abbrev)))))

;;;###autoload
(defun skk-comp-search-current-buffer (key &optional abbrev)
  (let (c-word)
    (save-match-data
      ;; `case-fold-search' $B$O!"<-=q%P%C%U%!$G$O>o$K(B nil$B!#(B
      (while (and (not c-word)
		  (search-forward
		   (concat "\n"
			   (if skk-use-numeric-conversion
			       (skk-num-compute-henkan-key key)
			     key))
		   nil t))
	(unless (eq (following-char)
		    ?\040) ;SPC
	  (setq c-word
		(concat key
			(buffer-substring-no-properties
			 ;; $B8+=P$78l$K6uGr$O4^$^$l$J$$!#(B
			 ;; " /" $B$r%5!<%A$9$kI,MW$O$J$$!#(B
			 (point)
			 (1- (search-forward " ")))))
	  (when (and abbrev
		     (string-match "\\Ca" c-word))
	    ;; abbrev $B%b!<%I$G!V(B3$B$M$s!W$J$I$NJd40$O$7$J$$(B
	    (setq c-word nil))))
      c-word)))

;;;###autoload
(defun skk-comp-previous ()
  ;; skk-abbrev-comma, skk-insert-comma $B$N%5%V%k!<%A%s!#(B
  ;; $BD>A0$KJd40$r9T$C$?8+=P$7$rA^F~$9$k!#(B
  (let ((inhibit-quit t)
	(stack-length (length skk-comp-stack))
	c-word)
    (if (and skk-comp-circulate (= skk-comp-depth stack-length))
	(setq skk-comp-depth 0)
      (setq skk-comp-depth (1+ skk-comp-depth)))
    (setq c-word (nth skk-comp-depth skk-comp-stack))
    (cond
     (c-word
      (delete-region skk-henkan-start-point (point))
      (insert c-word))
     (t
      (if (null skk-comp-circulate)
	  ;; non-circulate $B$J$i$P(B skk-comp-depth $B$,HO0O30$J$N$G(B 1 $BLa$9(B
	  (setq skk-comp-depth (1- skk-comp-depth))
	(delete-region skk-henkan-start-point (point))
	(insert skk-comp-key))
      ;;(setq skk-comp-depth (1- skk-comp-depth))
      (ding)
      (skk-message "\"%s\"$B$GJd40$9$Y$-8+=P$78l$OB>$K$"$j$^$;$s(B"
		   "No more previous completions for \"%s\""
		   (if skk-comp-use-prefix
		       (concat skk-comp-key skk-comp-prefix)
		     skk-comp-key))))))

;;;###autoload
(defun skk-comp-previous/next (ch)
  (setq this-command 'skk-comp-do)
  (cond ((eq ch skk-next-completion-char)
	 (skk-comp-do nil))
	((eq ch skk-previous-completion-char)
	 (skk-previous-completion))))

;;;###autoload
(defun skk-comp-by-history ()
  ;; skk-comp-prefix $B$r9MN8(B
  "$BF~NO$,6u$N;~$KMzNr$+$iJd40$9$k!#(B
$BBP>]$O8=:_$N(B Emacs $B$N%;%C%7%g%s$K$*$$$F9T$J$C$?Aw$jL5$7JQ49$N$&$A!"(B
`skk-kakutei-history-limit' $B$G;XDj$5$l$k:G6a$N$b$N$G$"$k!#(B"
  (when (and (string= skk-comp-key "")
	     (or (not skk-comp-use-prefix)
		 (string= skk-comp-prefix "")))
    (when skk-comp-first
      (let (list
	    el)
	(dolist (cell skk-kakutei-history)
	  (setq el (car cell))
	  (unless (member el list)
	    (push el list)))
	(setq skk-comp-kakutei-midasi-list
	      (nreverse list))))
    (pop skk-comp-kakutei-midasi-list)))

;;;###autoload
(defun skk-completion-search (comp-prog-list &optional search-prog-list without-midasi)
  "$BJQ49%-!<$GJd40$r9T$$!"F@$i$l$?3F8+=P$7$G$5$i$K8!:w$9$k!#(B
COMP-PROG-LIST $B$O(B `skk-completion-prog-list' $B$HF1$87A<0$G!"(B
$B$3$l$K4^$^$l$kJd404X?t$K$h$C$F!"$^$:JQ49%-!<$+$i8+=P$7$N%j%9%H$rF@$k!#(B
SEARCH-PROG-LIST $B$O(B `skk-search-prog-list' $B$HF1$87A<0$G!"(B
$BJd404X?t$K$h$C$FF@$?8+=P$7$r$3$l$K4^$^$l$k8!:w4X?t$K$h$jJQ498uJd$rF@$k!#(B
$B%G%U%)%k%H$G$O!"Jd40$K$h$C$FF@$i$l$?8+=P$7$HBP1~$9$k8uJd$O%;%C%H$G$"$k$,!"(B
WITHOUT-MIDASI $B$r;XDj$9$k$H8+=P$7$O>J$+$l$k!#(B"
  (when (eq (aref skk-henkan-key (1- (length skk-henkan-key)))
	    skk-completion-search-char)
    (let* ((key (substring skk-henkan-key 0 (1- (length skk-henkan-key))))
	   (skk-comp-use-prefix nil)
	   (midasi-list (skk-comp-get-all-candidates key "" comp-prog-list))
	   tmp words)
      (dolist (midasi midasi-list)
	(setq tmp (skk-search-progs midasi
				    (or search-prog-list
					skk-search-prog-list)))
	(when tmp	; $BJd40BP>]$H8!:wBP>]$OFHN)$J$N$GB8:_$7$J$$;v$b(B
	  (unless without-midasi
	    (setq words (nconc words (list midasi))))
	  ;; SKK $BK\BN$G(B skk-nunion $B$7$F$k$N$G$3$3$G$O9bB.@-=E;k(B
	  (setq words (nconc words tmp))))
      words)))

(defalias 'skk-previous-completion 'skk-comp-previous)
(defalias 'skk-start-henkan-with-completion 'skk-comp-start-henkan)

(run-hooks 'skk-comp-load-hook)

(require 'product)
(product-provide
    (provide 'skk-comp)
  (require 'skk-version))

;;; skk-comp.el ends here
