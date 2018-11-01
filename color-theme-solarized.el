;;; Author: Ethan Schoonover, Lunarized; Greg Pfeil, Emacs adaptation
;;; URL: http://ethanschoonover.com/lunarized

;;; This file is not (YET) part of GNU Emacs.

;;; # Usage

;;; 1. Install the color-theme package
;;;   (http://www.emacswiki.org/cgi-bin/wiki/ColorTheme)
;;; 2. Load this file
;;; 3. M-x color-theme-lunarized

(let ((current-file-name (or load-file-name buffer-file-name)))
  (if current-file-name
    (let* ((reqname (concat (file-name-directory current-file-name)
                            "lunarized-definitions.el"))
           (compreqname (concat reqname "c")))
      (require 'lunarized-definitions
               (if (file-exists-p compreqname) compreqname reqname)))
    (require 'lunarized-definitions)))

(eval-when-compile
  (require 'color-theme))

;;;###autoload
(defun color-theme-lunarized ()
  "Color theme by Ethan Schoonover, created 2011-03-24.
Ported to Emacs by Greg Pfeil, http://ethanschoonover.com/lunarized."
  (interactive)
  (color-theme-install
   `(color-theme-lunarized () () ,@(lunarized-color-definitions))))

(when (boundp 'color-themes)
  (add-to-list 'color-themes
               `(color-theme-lunarized
                 "Lunarized"
                 ,lunarized-description)))

;;;###autoload
(defun color-theme-lunarized-dark ()
  "Color theme by Ethan Schoonover, created 2011-03-24.
Ported to Emacs by Greg Pfeil, http://ethanschoonover.com/lunarized."
  (declare (obsolete color-theme-lunarized "2013-05-01"))
  (color-theme-lunarized))
;;;###autoload
(defun color-theme-lunarized-light ()
  "Color theme by Ethan Schoonover, created 2011-03-24.
Ported to Emacs by Greg Pfeil, http://ethanschoonover.com/lunarized."
  (declare (obsolete color-theme-lunarized "2013-05-01"))
  (color-theme-lunarized))

(provide 'color-theme-lunarized)
