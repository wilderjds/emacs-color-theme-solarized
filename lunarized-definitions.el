(eval-when-compile
  (unless (require 'cl-lib nil t)
    (require 'cl)
    (defalias 'cl-case 'case))
  )

(defconst lunarized-description
  "Color theme by Ethan Schoonover, created 2011-03-24.
http://ethanschoonover.com/lunarized
Ported to Emacs by Greg Pfeil, Desaturated base by Jacopo De Simoi")

(defcustom lunarized-termcolors 16
  "This is set to 16 by default, meaning that Lunarized will attempt to use the
standard 16 colors of your terminal emulator. You will need to set those colors
to the correct Lunarized values either manually or by importing one of the many
colorscheme available for popular terminal emulators and Xdefaults."
  :type 'integer
  :options '(16 256)
  :group 'lunarized)

(defcustom lunarized-degrade nil
  "For test purposes only; when in GUI mode, forces Lunarized to use the 256
degraded color mode to test the approximate color values for accuracy."
  :type 'boolean
  :group 'lunarized)

(defcustom lunarized-diff-mode 'normal
  "Sets the level of highlighting to use in diff-like modes."
  :type 'symbol
  :options '(high normal low)
  :group 'lunarized)

(defcustom lunarized-bold t
  "Stops Lunarized from displaying bold when nil."
  :type 'boolean
  :group 'lunarized)

(defcustom lunarized-underline t
  "Stops Lunarized from displaying underlines when nil."
  :type 'boolean
  :group 'lunarized)

(defcustom lunarized-italic t
  "Stops Lunarized from displaying italics when nil."
  :type 'boolean
  :group 'lunarized)

(defcustom lunarized-contrast 'normal
  "Stick with normal! It's been carefully tested. Setting this option to high or
low does use the same Lunarized palette but simply shifts some values up or
down in order to expand or compress the tonal range displayed."
  :type 'symbol
  :options '(high normal low)
  :group 'lunarized)

(defcustom lunarized-broken-srgb
  (if (and (eq system-type 'darwin) (eq window-system 'ns))
      (not (and (boundp 'ns-use-srgb-colorspace)
                ns-use-srgb-colorspace))
    nil)
  "Emacs bug #8402 results in incorrect color handling on Macs. If this is t
\(the default on Macs), Lunarized works around it with alternative colors.
However, these colors are not totally portable, so you may be able to edit
the \"Gen RGB\" column in lunarized-definitions.el to improve them further."
  :type 'boolean
  :group 'lunarized)

;; FIXME: The Generic RGB colors will actually vary from device to device, but
;;        hopefully these are closer to the intended colors than the sRGB values
;;        that Emacs seems to dislike
(defvar lunarized-colors           ; ANSI(Lunarized terminal)
  ;; name     sRGB      Gen RGB   256       16              8
  '((base03  "#262626"   "#1c1c1c" "#1c1c1c" "brightblack"   "black")
    (base02  "#303030"   "#242424" "#262626" "black"         "black")
    (base01  "#6a6a6a"   "#575757" "#585858" "brightgreen"   "green")
    (base00  "#777777"   "#646464" "#626262" "brightyellow"  "yellow")
    (base0   "#919191"   "#7e7e7e" "#808080" "brightblue"    "blue")
    (base1   "#9e9e9e"   "#8c8c8c" "#8a8a8a" "brightcyan"    "cyan")
    (base2   "#e8e8e8"   "#e2e2e2" "#e4e4e4" "white"         "white")
    (base3   "#f6f6f6"   "#f4f4f4" "#ffffd7" "brightwhite"   "white")
    (yellow  "#b58900" "#a57705" "#af8700" "yellow"        "yellow")
    (orange  "#cb4b16" "#bd3612" "#d75f00" "brightred"     "red")
    (red     "#dc322f" "#c60007" "#d70000" "red"           "red")
    (magenta "#d33682" "#c61b6e" "#af005f" "magenta"       "magenta")
    (violet  "#6c71c4" "#5859b7" "#5f5faf" "brightmagenta" "magenta")
    (blue    "#268bd2" "#2075c7" "#0087ff" "blue"          "blue")
    (cyan    "#2aa198" "#259185" "#00afaf" "cyan"          "cyan")
    (green   "#859900" "#728a05" "#5f8700" "green"         "green"))
  "This is a table of all the colors used by the Lunarized color theme. Each
   column is a different set, one of which will be chosen based on term
   capabilities, etc.")

(defun lunarized-face-for-index (facespec index &optional light)
  "Creates a face from facespec where the colors use the names from
  `lunarized-colors`."
  (let ((new-fontspec (copy-sequence facespec)))
    (dolist (property '(:foreground :background :color))
      (let ((color-name (plist-get new-fontspec property)))
        (when color-name
          ;; NOTE: We try to turn an 8-color term into a 10-color term by not
          ;;       using default background and foreground colors, expecting the
          ;;       user to have the right colors set for them.
          (when (and (= index 5)
                     (or (and (eq property :background)
                              (eq color-name 'back))
                         (and (eq property :foreground)
                              (member color-name '(base0 base1)))))
            (setf color-name nil))
          (when (eq color-name 'back)
            (setf color-name 'base03))
          (when light
            (setf color-name
                  (cl-case color-name
                    (base03 'base3)
                    (base02 'base2)
                    (base01 'base1)
                    (base00 'base0)
                    (base0 'base00)
                    (base1 'base01)
                    (base2 'base02)
                    (base3 'base03)
                    (otherwise color-name))))
          (plist-put new-fontspec
                     property
                     (nth index (assoc color-name lunarized-colors))))))
    (when (plist-get new-fontspec :box)
      (plist-put new-fontspec
                 :box
                 (lunarized-face-for-index (plist-get new-fontspec :box) index
                                           light)))
    new-fontspec))

(defun create-face-spec (name facespec)
  `(,name ((((background dark) (type graphic))
            ,(lunarized-face-for-index facespec
                                       (cond (lunarized-degrade     3)
                                             (lunarized-broken-srgb 2)
                                             (t                     1))))
           (((background dark) (type tty) (min-colors 256))
            ,(lunarized-face-for-index facespec
                                       (if (= lunarized-termcolors 16) 4 3)))
           (((background dark) (type tty) (min-colors  16))
            ,(lunarized-face-for-index facespec 4))
           (((background dark) (type tty) (min-colors   8))
            ,(lunarized-face-for-index facespec 5))
           (((background light) (type graphic))
            ,(lunarized-face-for-index facespec
                                       (cond (lunarized-degrade     3)
                                             (lunarized-broken-srgb 2)
                                             (t                     1))
                                       t))
           (((background light) (type tty) (min-colors 256))
            ,(lunarized-face-for-index facespec
                                       (if (= lunarized-termcolors 16) 4 3)
                                       t))
           (((background light) (type tty) (min-colors  16))
            ,(lunarized-face-for-index facespec 4 t))
           (((background light) (type tty) (min-colors   8))
            ,(lunarized-face-for-index facespec 5 t)))))

(defun lunarized-color-definitions ()
  (let ((bold        (if lunarized-bold 'bold        'unspecified))
        (bright-bold (if lunarized-bold 'unspecified 'bold))
        (underline   (if lunarized-underline t 'unspecified))
        (opt-under   'unspecified)
        (italic      (if lunarized-italic 'italic 'unspecified)))
    (cond ((eq 'high lunarized-contrast)
           (let ((orig-base3 base3))
             (rotatef base01 base00 base0 base1 base2 base3)
             (setf base3 orig-base3)))
          ((eq 'low lunarized-contrast)
           (setf back      base02
                 opt-under t)))
    (let ((bg-back   '(:background back))
          (bg-base03 '(:background base03))
          (bg-base02 '(:background base02))
          (bg-base01 '(:background base01))
          (bg-base00 '(:background base00))
          (bg-base0 '(:background base0))
          (bg-base1 '(:background base1))
          (bg-base2 '(:background base2))
          (bg-base3 '(:background base3))
          (bg-green '(:background green))
          (bg-yellow '(:background yellow))
          (bg-orange '(:background orange))
          (bg-red '(:background red))
          (bg-magenta '(:background magenta))
          (bg-violet '(:background violet))
          (bg-blue '(:background blue))
          (bg-cyan '(:background cyan))

          (fg-base03 '(:foreground base03))
          (fg-base02 '(:foreground base02))
          (fg-base01 '(:foreground base01))
          (fg-base00 '(:foreground base00))
          (fg-base0 '(:foreground base0))
          (fg-base1 '(:foreground base1))
          (fg-base2 '(:foreground base2))
          (fg-base3 '(:foreground base3))
          (fg-green '(:foreground green))
          (fg-yellow '(:foreground yellow))
          (fg-orange '(:foreground orange))
          (fg-red '(:foreground red))
          (fg-magenta '(:foreground magenta))
          (fg-violet '(:foreground violet))
          (fg-blue '(:foreground blue))
          (fg-cyan '(:foreground cyan))

          (fmt-none   `())
          (fmt-bold   `(:weight ,bold))
          (fmt-bldi   `(:weight ,bold :slant ,italic))
          (fmt-undr   `(                             :underline ,underline))
          (fmt-undb   `(:weight ,bold                :underline ,underline))
          (fmt-undi   `(              :slant ,italic :underline ,underline))
          (fmt-uopt   `(                             :underline ,opt-under))
          ;; FIXME: don’t hardcode the SRGB color names
          (fmt-curl-red    `(                        :underline (:color red :style wave)))
	      (fmt-undr-red    `(                        :underline (:color "#dc322f")))
          (fmt-curl-yellow `(                        :underline (:color "#b58900" :style wave)))
	      (fmt-undr-yellow `(                        :underline (:color "#b58900")))
          (fmt-curl-magenta `(                       :underline (:color "#d33682" :style wave)))
	      (fmt-undr-magenta `(                       :underline (:color "#d33682" )))
          (fmt-curl-cyan `(                          :underline (:color "#2aa198" :style wave)))
          (fmt-ital   `(              :slant ,italic))
          ;; FIXME: not quite the same
          (fmt-stnd   `(                                                   :inverse-video t))
          (fmt-revr   `(                                                   :inverse-video t))
          (fmt-revb   `(:weight ,bold                                      :inverse-video t))
          (fmt-revbb  `(:weight ,bright-bold                               :inverse-video t))
          (fmt-revbbu `(:weight ,bright-bold         :underline ,underline :inverse-video t)))
      (eval-after-load 'ansi-color
        '(setf ansi-color-names-vector [,base02 ,red ,green ,yellow ,blue ,magenta ,cyan ,base00]))
      (mapcar (lambda (face) (apply 'create-face-spec face))
              `(;; basic
                (default (,@fg-base0 ,@bg-back))  ; Normal
                (cursor (,@fg-base03 ,@bg-base0)) ; Cursor
                (shadow (,@fg-base01))
                (link (,@fmt-undr ,@fg-violet)) ; Underlined
                (link-visited (,@fmt-undr ,@fg-magenta))
                (match (,@fmt-revr ,@fg-yellow))    ; Search
                (error (,@fmt-revr ,@fg-magenta))   ; ErrorMsg
                (warning (,@fmt-bold ,@fg-magenta)) ; WarningMsg
                (success (,@fg-blue))               ; MoreMsg
                (escape-glyph-face (,@fg-red))
                (fringe (,@fg-base00 ,@bg-back))
                (linum (,@fg-base01 ,@bg-base03))
                (header-line (,@fg-base0 ,@bg-base02 ,@fmt-revbb)) ; Pmenu
                (highlight (,@bg-base02))
                (hl-line (:underline ,opt-under ,@bg-base02)) ; CursorLine
                (isearch (,@fmt-stnd ,@fg-orange ,@bg-back)) ; IncSearch
                (isearch-fail (,@fmt-undr-magenta)) ; ErrorMsg
                (lazy-highlight (:inherit match))   ; Search
                (menu (,@fg-base0 ,@bg-base02))
                (minibuffer-prompt (,@fmt-bold ,@fg-cyan)) ; Question
                (mode-line              ; StatusLine
                 (,@fg-base1 ,@bg-base02 :box nil))
                (mode-line-inactive     ; StatusLineNC
                 (,@fg-base0 ,@bg-base02 :box nil))
                (mode-line-indicator ; StatusLineNC
                 (,@fg-red ,@bg-base02 :box nil))
                (mode-line-inactive-indicator     ; StatusLineNC
                 (,@fg-base01 ,@bg-base02 :box nil))
                (region (,@fg-base01 ,@bg-base3)) ; Visual
                (secondary-selection (,@bg-base02))
                (shadow (,@fg-base01))
                (trailing-whitespace (,@fmt-revr ,@fg-magenta))
                (vertical-border (,@fg-base0))
                ;; comint
                (comint-highlight-prompt (,@fg-blue))
                ;; compilation
                (compilation-info (,@fmt-bold ,@fg-green))
                (compilation-warning (,@fmt-bold ,@fg-orange))
                (compilation-mode-line-run ( ,@fg-orange))
                (compilation-mode-line-exit ( ,@fg-green))
                (compilation-mode-line-fail (,@fmt-revr ,@fg-magenta))
                ;; custom
                (custom-button
                 (,@fg-base1 ,@bg-base02 :box (:line-width 2 :style released-button)))
                (custom-button-mouse
                 (,@fmt-revr ,@fg-base1 ,@bg-base02 :inherit custom-button))
                (custom-button-pressed
                 (,@fmt-revr ,@fg-base1 ,@bg-base02
                             :box (:line-width 2 :style pressed-button)
                             :inherit custom-button-mouse))
                (custom-changed (,@fmt-revr ,@fg-blue ,@bg-base3))
                (custom-comment (,@fg-base1 ,@bg-base02))
                (custom-comment-tag (,@fg-base1 ,@bg-base02))
                (custom-documentation (:inherit default))
                (custom-group-tag (,@fg-base1))
                (custom-group-tag-1 (,@fmt-bold ,@fg-base1))
                (custom-invalid (,@fmt-revr ,@fg-red ,@bg-back))
                (custom-link (,@fg-violet))
                (custom-state (,@fg-green))
                (custom-variable-tag (,@fg-base1))
                ;; diff - DiffAdd, DiffChange, DiffDelete, and DiffText
                ,@(cl-case lunarized-diff-mode
                    (high
                     `((diff-added (,@fmt-revr ,@fg-green))
                       (diff-changed (,@fmt-revr ,@fg-yellow))
                       (diff-removed (,@fmt-revr ,@fg-red))
                       (diff-refine-change
                        (,@fmt-revr ,@fg-blue ,@bg-back))))
                    (low
                     `((diff-added (,@fmt-undr ,@fg-green))
                       (diff-changed (,@fmt-undr ,@fg-yellow))
                       (diff-removed (,@fmt-bold ,@fg-red))
                       (diff-refine-change (,@fmt-undr ,@fg-blue ,@bg-back))))
                    (normal
                     (if window-system
                         `((diff-added (,@fmt-bold ,@fg-green ,@bg-base02))
                           (diff-changed (,@fmt-bold ,@fg-yellow ,@bg-base02))
                           (diff-removed (,@fmt-bold ,@fg-red ,@bg-base02))
                           (diff-refine-change (,@fmt-bold ,@fg-blue ,@bg-base02)))
                       `((diff-added (,@fg-green ,@bg-base02))
                         (diff-changed (,@fg-yellow ,@bg-base02))
                         (diff-removed (,@fg-red ,@bg-base02))
                         (diff-refine-change (,@fg-blue ,@bg-base02))))))
                (diff-refine-added (:inherit diff-added ,@fmt-revr))
                (diff-refine-removed (:inherit diff-removed ,@fmt-revr))
                (diff-file-header (:inherit default ,@fg-blue))
                (diff-hunk-header (:inherit default))
                (diff-header (,@fg-base1 ,@bg-back))
                ;; IDO
                (ido-only-match (,@fg-green))
                (ido-subdir (,@fg-blue))
                (ido-first-match (,@fmt-bold ,@fg-green))
                ;; emacs-wiki
                (emacs-wiki-bad-link-face (,@fmt-undr ,@fg-magenta))
                (emacs-wiki-link-face (,@fmt-undr ,@fg-blue))
                (emacs-wiki-verbatim-face (,@fmt-undr ,@fg-base00))
                ;; eshell
                (eshell-ls-archive (,@fg-magenta))
                (eshell-ls-backup (,@fg-yellow))
                (eshell-ls-clutter (,@fg-orange))
                (eshell-ls-directory (,@fg-blue)) ; Directory
                (eshell-ls-executable (,@fg-green))
                (eshell-ls-missing (,@fg-red))
                (eshell-ls-product (,@fg-yellow))
                (eshell-ls-readonly (,@fg-base1))
                (eshell-ls-special (,@fg-violet))
                (eshell-ls-symlink (,@fg-cyan))
                (eshell-ls-unreadable (,@fg-base00))
                (eshell-prompt (,@fmt-bold ,@fg-green))
                ;; elfeed
                (elfeed-search-date-face (,@fg-violet))
                (elfeed-search-title-face (,@fg-base0))
                (elfeed-search-feed-face (,@fg-yellow))
                (elfeed-search-tag-face (,@fg-green))
                ;; font-lock
                (font-lock-builtin-face (,@fmt-none ,@fg-green)) ; Statement
                (font-lock-comment-face (,@fmt-ital ,@fg-base01)) ; Comment
                (font-lock-constant-face (,@fmt-none ,@fg-cyan)) ; Constant
                (font-lock-function-name-face (,@fmt-none ,@fg-blue)) ; Identifier
                (font-lock-keyword-face (,@fmt-none ,@fg-orange)) ; Statement
                (font-lock-string-face (,@fmt-none ,@fg-cyan)) ; Constant
                (font-lock-type-face (,@fmt-none ,@fg-green))  ; Type
                (font-lock-variable-name-face (,@fmt-none ,@fg-blue)) ; Identifier
                (font-lock-warning-face (,@fmt-bold ,@fg-magenta)) ; Error
                (font-lock-doc-face (,@fmt-ital ,@fg-base01)) ; Comment
                (font-lock-doc-string-face ; Comment (XEmacs-only)
                 (,@fmt-ital ,@fg-base01))
                (font-lock-color-constant-face (,@fmt-none ,@fg-green))
                (font-lock-comment-delimiter-face ; Comment
                 (,@fmt-ital ,@fg-base01))
                (font-lock-preprocessor-face (,@fmt-none ,@fg-yellow)) ; PreProc
                (font-lock-reference-face (,@fmt-none ,@fg-cyan))
                (font-lock-negation-char-face (,@fmt-none ,@fg-magenta))
                (font-lock-other-type-face (,@fmt-ital ,@fg-blue))
                (font-lock-regexp-grouping-construct (,@fmt-none ,@fg-orange))
                (font-lock-special-keyword-face (,@fmt-none ,@fg-red)) ; Special
                (font-lock-exit-face (,@fmt-none ,@fg-red))
                (font-lock-other-emphasized-face (,@fmt-bldi ,@fg-violet))
                (font-lock-regexp-grouping-backslash (,@fmt-none ,@fg-yellow))
		        ;; LaTeX
		        (font-latex-math-face (,@fmt-none ,@fg-base1)) ; Type
		        (font-latex-sedate-face (,@fmt-none ,@fg-yellow)) ; Type
                (font-latex-italic-face (,@fmt-none ,@fg-green))
                (font-latex-string-face (,@fmt-none ,@fg-cyan))
                (font-latex-verbatim-face (,@fmt-none ,@fg-orange))
                (font-latex-special-comment-face (,@fmt-none ,@fg-violet))
                ;; avy
                (avy-lead-face (,@fmt-none ,@fg-red))
                (avy-lead-face-0 (,@fmt-none ,@fg-blue))
                (avy-lead-face-1 (,@fmt-none ,@fg-green))
                (avy-lead-face-1 (,@fmt-none ,@fg-yellow))
                (avy-background (,@fmt-none ,@fg-base01))

                ;; info
                (info-xref (:inherit link))
                (info-xref-visited (:inherit link-visited))
                (info-menu-header (:inherit outline-1))
                ;; org
                (org-block-background (,@bg-base02))
                (org-hide (,@fg-base03))
                (org-todo (,@fmt-bold ,@fg-red))
                (org-done (,@fmt-bold ,@fg-green))
                (org-todo-kwd-face (,@fmt-bold ,@fg-base03 ,@bg-red))
                (org-done-kwd-face (,@fmt-bold ,@fg-green))
                (org-project-kwd-face (,@fg-violet ,@bg-base03))
                (org-waiting-kwd-face (,@fg-orange ,@bg-base03))
                (org-someday-kwd-face (,@fg-blue ,@bg-base03))
                (org-started-kwd-face (,@fg-yellow ,@bg-base03))
                (org-cancelled-kwd-face (,@fg-green ,@bg-base03))
                (org-delegated-kwd-face (,@fg-cyan ,@bg-base03))
                (org-default (:inherit default))
                (org-level-1 (:inherit outline-1))
                (org-level-2 (:inherit outline-2))
                (org-level-3 (:inherit outline-3))
                (org-level-4 (:inherit outline-4))
                (org-level-5 (:inherit outline-5))
                (org-level-6 (:inherit outline-6))
                (org-level-7 (:inherit outline-7))
                (org-level-8 (:inherit outline-8))
                (org-special-keyword (,@fmt-ital ,@fg-base01))
                (org-drawer (,@fmt-bold ,@fg-blue))
                (org-column (,@fmt-revr ,@fg-cyan))
                (org-column-title (,@fmt-bold ,@fmt-revr))
                (org-warning (,@fmt-bold ,@fg-red))
                (org-archived (,@fg-base01))
                (org-link (,@fmt-undr ,@fg-violet))
                (org-footnote (,@fmt-undr ,@fg-violet))
                (org-ellipses (,@fg-yellow :strike-through t) )
                (org-target (,@fmt-undr))
                (org-date (,@fmt-undr ,@fg-violet))
                (org-date-selected (,@fmt-revr ,@fg-red))
                (org-sexp-date (,@fmt-undr ,@fg-violet))
                (org-tag (,@fg-yellow))
                (org-list-dt (,@fmt-bold))
                (org-agenda-done (,@fg-green))
                (org-headline-done (,@fg-base01))
                (org-priority (,@fmt-ital ,@fg-base01))
                (org-checkbox (,@fmt-bold))
                (org-table (,@fg-cyan))
                (org-formula (:weight bold :slant italic ,@fg-red))
                (org-code (,@fg-base01))
                (org-document-title (,@fmt-bold ,@fg-cyan))
                (org-roam-title (,@fg-cyan))
                (org-document-info-keyword (,@fg-base01))
                (org-document-info (,@fg-green))
                (org-block (,@fg-base01))
                (org-verbatim (,@fmt-undr ,@fg-base01))
                (org-clock-overlay (,@fmt-revr ,@bg-cyan ,@fg-base03))
                (org-agenda-structure (,@fmt-bold ,@fg-blue))
                (org-scheduled (:weight bold :slant italic ,@fg-green))
                (org-scheduled-today (:weight bold :slant italic ,@fg-green))
                (org-agenda-dimmed-todo-face (,@fg-base00))
                (org-scheduled-previously (,@fmt-bold ,@fg-red))
                (org-upcoming-deadline (,@fmt-bold ,@fg-red))
                (org-agenda-restriction-lock (,@fmt-revr ,@fg-base03 ,@bg-cyan))
                (org-time-grid (,@fg-yellow))
                (org-latex-and-related(,@fg-orange))

                (org-habit-clear-face (,@fg-blue ))
                (org-habit-clear-future-face (,@fg-blue ))
                (org-habit-ready-face (,@fg-green ))
                (org-habit-ready-future-face (,@fg-green ))
                (org-habit-alert-face (,@fg-yellow ))
                (org-habit-alert-future-face (,@fg-yellow ))
                (org-habit-overdue-face (,@fg-magenta ))
                (org-habit-overdue-future-face (,@fg-magenta ))

                ;; table
                (table-cell (,@fmt-none ,@fg-base0 ,@bg-back))
                ;; outline - pandocBlockQuoteLeader[1–6]
                (outline-1 (,@fg-blue))
                (outline-2 (,@fg-cyan))
                (outline-3 (,@fg-yellow))
                (outline-4 (,@fg-red))
                (outline-5 (,@fg-base0))
                (outline-6 (,@fg-base01))
                (outline-7 (,@fg-orange))
                (outline-8 (,@fg-violet))
                ;; show-paren - MatchParen
                (show-paren-match ( ,@fmt-revr ,@fg-green ))
                (show-paren-mismatch ( ,@fmt-revr ,@fg-magenta))
                ;; speedbar
                ;; (speedbar-button-face (,@fmt-none ,@fg-base1))
                (speedbar-button-face
                 (,@fg-base1 ,@bg-base02
                             :box (:line-width 2 :style released-button)))
                (speedbar-directory-face (,@fmt-none ,@fg-blue))
                (speedbar-file-face (,@fmt-none ,@fg-green))
                ;; (speedbar-highlight-face (,@bg-base02))
                (speedbar-highlight-face
                 (,@fmt-revr ,@fg-base1 ,@bg-base02
                             :inherit speedbar-button-face))
                ;; (speedbar-selected-face (,@fmt-undr ,@fg-yellow))
                (speedbar-selected-face (,@fmt-none ,@bg-base02 ,@fg-green))
                (speedbar-separator-face (,@fmt-stnd))
                (speedbar-tag-face (,@fmt-none ,@fg-blue))
                ;; widgets
                (widget-field
                 (,@fg-base1 ,@bg-base02 :box (:line-width 1 :color base2)
                             :inherit default))
                (widget-single-line-field (:inherit widget-field))
                ;; extra modules
                ;; -------------
                ;; alert
                (alert-urgent (,@fg-red))
                (alert-high (,@fg-orange))
                (alert-moderate (,@fg-yellow))
                (alert-normal (,@fg-green))
                (alert-low (,@fg-blue))
                (alert-trivial (,@fg-violet))
                ;; col-highlight -- Highlight the current column.
                ;; http://www.emacswiki.org/emacs/col-highlight.el
                (col-highlight (,@bg-base02))
                ;; ace-jump-mode
                (ace-jump-face-background (,@fmt-none ,@fg-base01))
                (ace-jump-face-foreground (,@fmt-bold ,@fg-red))
                ;; bm visual bookmarks
                (bm-fringe-face (,@bg-orange ,@fg-base03))
                (bm-fringe-persistent-face (,@bg-blue ,@fg-base03))
                (bookmark-face (,@fg-orange ))
                ;; Flymake
                (flymake-errline (,@fmt-bold ,@fg-magenta)) ; Error
                (flymake-warnline (,@fmt-bold ,@fg-magenta))
                ;; column-marker
                (column-marker-1 (,@bg-base01))
                (column-marker-2 (,@bg-cyan))
                (column-marker-3 (,@bg-violet))
                ;; jabber
                (jabber-activity-face (,@fmt-bold ,@fg-red))
                (jabber-activity-personal-face (,@fmt-bold ,@fg-blue))
                (jabber-chat-error (,@fmt-bold ,@fg-red))
                (jabber-chat-prompt-foreign (,@fmt-bold ,@fg-red))
                (jabber-chat-prompt-local (,@fmt-bold ,@fg-blue))
                (jabber-chat-prompt-system (,@fmt-bold ,@fg-green))
                (jabber-chat-text-foreign (,@fg-base1))
                (jabber-chat-text-local (,@fg-base0))
                (jabber-chat-rare-time-face (,@fmt-undr ,@fg-green))
                (jabber-roster-user-away (,@fmt-ital ,@fg-green))
                (jabber-roster-user-chatty (,@fmt-bold ,@fg-orange))
                (jabber-roster-user-dnd (,@fmt-ital ,@fg-red))
                (jabber-roster-user-error
                 (:weight light :slant italic ,@fg-red))
                (jabber-roster-user-offline (,@fg-base01))
                (jabber-roster-user-online (,@fmt-bold ,@fg-blue))
                (jabber-roster-user-xa (,@fmt-ital ,@fg-magenta))
                ;; git-gutter
                (git-gutter:modified (,@fg-violet))
                (git-gutter:added (,@fg-green))
                (git-gutter:deleted (,@fg-red))
                ;; gnus - these are mostly taken from mutt, not VIM
                (gnus-cite-1 (:inherit outline-1))
                (gnus-cite-2 (:inherit outline-2))
                (gnus-cite-3 (:inherit outline-3))
                (gnus-cite-4 (:inherit outline-4))
                (gnus-cite-5 (:inherit outline-5))
                (gnus-cite-6 (:inherit outline-6))
                (gnus-cite-7 (:inherit outline-7))
                (gnus-cite-8 (:inherit outline-8))
                (gnus-cite-9 (,@fg-green))
                (gnus-cite-10 (,@fg-magenta))
                (gnus-cite-11 (,@fg-base02))
                (gnus-group-mail-1 (,@fmt-bold ,@fg-base3))
                (gnus-group-mail-1-empty (,@fg-base3))
                (gnus-group-mail-2 (,@fmt-bold ,@fg-base2))
                (gnus-group-mail-2-empty (,@fg-base2))
                (gnus-group-mail-3 (,@fmt-bold ,@fg-magenta))
                (gnus-group-mail-3-empty (,@fg-magenta))
                (gnus-group-mail-low (,@fmt-bold ,@fg-base00))
                (gnus-group-mail-low-empty (,@fg-base00))
                (gnus-group-news-1 (,@fmt-bold ,@fg-base1))
                (gnus-group-news-1-empty (,@fg-base1))
                (gnus-group-news-2 (,@fmt-bold ,@fg-blue))
                (gnus-group-news-2-empty (,@fg-blue))
                (gnus-group-news-low (,@fmt-bold ,@fg-violet))
                (gnus-group-news-low-empty (,@fg-violet))
                (gnus-emphasis-highlight-words ; highlight
                 (,@fmt-none ,fg-yellow))
                (gnus-header-content (,@fmt-none ,@fg-base01)) ; hdrdefault
                (gnus-header-from (,@fmt-none ,@fg-green)) ; header ^From
                (gnus-header-name (,@fmt-none ,@fg-yellow)) ; hdrdefault
                (gnus-header-newsgroups (,@fmt-none ,@fg-base02)) ; hdrdefault
                (gnus-header-subject (,@fmt-none ,@fg-blue)) ; header ^Subject
                (gnus-server-agent (,@fmt-bold ,@fg-base3))
                (gnus-server-closed (,@fmt-ital ,@fg-base1))
                (gnus-server-denied (,@fmt-bold ,@fg-base2))
                (gnus-server-offline (,@fmt-bold ,@fg-green))
                (gnus-server-opened (,@fmt-bold ,@fg-cyan))
                (gnus-signature (,@fmt-none ,@fg-base01)) ; signature
                (gnus-splash (,@fg-base2))
                (gnus-summary-cancelled ; deleted messages
                 (,@fmt-none ,@fg-red))
                (gnus-summary-high-ancient
                 (,@fmt-bold :inherit gnus-summary-normal-ancient))
                (gnus-summary-high-read
                 (,@fmt-bold :inherit gnus-summary-normal-read))
                (gnus-summary-high-ticked
                 (,@fmt-bold :inherit gnus-summary-normal-ticked))
                (gnus-summary-high-undownloaded
                 (,@fmt-bold :inherit gnus-summary-normal-undownloaded))
                (gnus-summary-high-unread
                 (,@fmt-bold :inherit gnus-summary-normal-unread))
                (gnus-summary-low-ancient
                 (,@fmt-ital :inherit gnus-summary-normal-ancient))
                (gnus-summary-low-read
                 (,@fmt-ital :inherit gnus-summary-normal-ancient))
                (gnus-summary-low-unread
                 (,@fmt-ital :inherit gnus-summary-normal-unread))
                (gnus-summary-low-ticked
                 (,@fmt-ital :inherit gnus-summary-normal-ancient))
                (gnus-summary-low-undownloaded
                 (,@fmt-ital :inherit gnus-summary-normal-ancient))
                (gnus-summary-normal-ancient ; old messages
                 (,@fmt-none ,@fg-blue))
                (gnus-summary-normal-read ; read messages
                 (,@fmt-none ,@fg-base01))
                (gnus-summary-normal-ticked (,@fmt-none ,@fg-red)) ; flagged
                (gnus-summary-normal-undownloaded (,@fmt-none ,@fg-base2))
                (gnus-summary-normal-unread ; unread messages
                 (,@fmt-none ,@fg-blue))
                (gnus-summary-selected  ; indicator
                 (,@fmt-none ,@fg-base03 ,@bg-yellow))
                ;;helm
                (helm-apt-deinstalled (,@fg-base01))
                (helm-apt-installed (,@fg-green))
                (helm-bookmark-addressbook (,@fg-blue))
                (helm-bookmark-directory (:inherit helm-ff-directory))
                (helm-bookmark-file (:inherit helm-ff-file))
                (helm-bookmark-gnus (,@fg-cyan))
                (helm-bookmark-info (,@fg-green))
                (helm-bookmark-man (,@fg-violet))
                (helm-bookmark-w3m (,@fg-yellow))
                (helm-bookmarks-su (,@fg-orange))
                (helm-buffer-not-saved (,@fg-orange))
                (helm-buffer-process (,@fg-magenta))
                (helm-buffer-saved-out (,@fmt-revr ,@fg-red ,@bg-back))
                (helm-buffer-size (,@fg-base01))
                (helm-candidate-number ( ,@fg-yellow))
                (helm-emms-playlist (,@fmt-none ,@fg-base01))
                (helm-etags+-highlight-face (:inherit highlight))
                (helm-ff-directory (,@bg-back ,@fg-blue))
                (helm-ff-executable (,@fmt-bold ,@fg-green))
                (helm-ff-file (:inherit default))
                (helm-ff-file-extension (,@fg-yellow))
                (helm-ff-invalid-symlink (,@fg-magenta))
                (helm-ff-prefix (,@fmt-revr ,@fg-yellow))
                (helm-ff-symlink (,@fmt-bold ,@fg-cyan))
                (helm-gentoo-match (:inherit helm-match))
                (helm-grep-cmd-line (:inherit diff-added))
                (helm-grep-file (,@fmt-undr ,@fg-cyan))
                (helm-grep-finish (,@fg-green))
                (helm-grep-lineno (,@fg-orange))
                (helm-grep-match (:inherit helm-match))
                (helm-grep-running (,@fg-red))
                (helm-helper (:inherit helm-header))
                (helm-history-deleted (:inherit helm-ff-invalid-symlink))
                (helm-history-remote (,@fg-red))
                (helm-lisp-completion-info (,@fg-base0))
                (helm-lisp-show-completion (,@fmt-bold ,@fg-yellow ,@bg-base02))
                (helm-ls-git-added-copied-face (,@fg-green))
                (helm-ls-git-conflict-face (,@fmt-bold ,@fg-red))
                (helm-ls-git-deleted-and-staged-face (,@fmt-ital ,@fg-base01))
                (helm-ls-git-deleted-not-staged-face (,@fmt-bold ,@fg-green))
                (helm-ls-git-modified-and-staged-face (,@fmt-ital ,@fg-base01))
                (helm-ls-git-modified-not-staged-face (,@fmt-ital ,@fg-base01))
                (helm-ls-git-renamed-modified-face (,@fg-green))
                (helm-ls-git-untracked-face (,@fg-red))
                (helm-mu-contacts-name-face (,@fg-yellow))
                (helm-mu-contacts-address-face (:inherit default))
                (helm-M-x-key (,@fmt-none ,@fg-orange))
                (helm-match (:inherit match))
                (helm-moccur-buffer (,@fmt-undr ,@fg-cyan))
                (helm-selection (:inherit region))
                (helm-selection-line (:inherit secondary-selection))
                (helm-separator (,@fg-red))
                (helm-source-header (,@fg-blue))
                (helm-time-zone-current (,@fg-green))
                (helm-time-zone-home (,@fg-red))
                (helm-visible-mark (,@fmt-bold ,@bg-back ,@fg-magenta))
                (helm-w3m-bookmarks (:inherit helm-bookmark-w3m))
                ;; help
                (help-key-binding (,@fg-orange ,@bg-base02))
                ;; markdown
                (markdown-bold-face (:inherit bold))
                (markdown-header-delimiter-face (:inherit shadow))
                (markdown-header-face (:inherit outline-1))
                (markdown-header-face-1 (:inherit outline-1))
                (markdown-header-face-2 (:inherit outline-2))
                (markdown-header-face-3 (:inherit outline-3))
                (markdown-header-face-4 (:inherit outline-4))
                (markdown-header-face-5 (:inherit outline-5))
                (markdown-header-face-6 (:inherit outline-6))
                (markdown-header-rule-face (:inherit shadow))
                (markdown-italic-face (:inherit italic))
                (markdown-link-face (:inherit shadow))
                (markdown-link-title-face (:inherit link))
                (markdown-url-face (:inherit link))
                ;; Message
                (message-mml (,@fg-blue))
                (message-cited-text (:inherit outline-1))
                (message-cited-text-1 (:inherit outline-1))
                (message-cited-text-2 (:inherit outline-2))
                (message-cited-text-3 (:inherit outline-3))
                (message-cited-text-4 (:inherit outline-4))
                (message-cited-text-5 (:inherit outline-5))
                (message-cited-text-6 (:inherit outline-6))
                (message-separator (,@fg-base01))
                (message-header-xheader (,@fg-violet))
                (message-header-name (,@fg-cyan))
                (message-header-other (,@fg-red))
                (message-header-newsgroups (,@fmt-bldi ,@fg-yellow))
                (message-header-subject (,@fg-base00))
                (message-header-cc (,@fmt-bold ,@fg-green))
                (message-header-to (,@fmt-bold ,@fg-base1))
                ;; minimap
                (minimap-active-region-background (,@bg-base02))
                (minimap-semantic-function-face (,bg-base3))
                (minimap-semantic-type-face (,bg-base3))
                (minimap-semantic-variable-face (,bg-base3))
                ;; parenface
                (parenface-bracket-face (:inherit shadow))
                (parenface-curly-face (:inherit shadow))
                (parenface-paren-face (:inherit shadow))
                ;; paren-face
                (parenthesis (:inherit shadow))
                ;; rainbow-delimiters
                (rainbow-delimiters-depth-1-face (:inherit outline-1))
                (rainbow-delimiters-depth-2-face (:inherit outline-2))
                (rainbow-delimiters-depth-3-face (:inherit outline-3))
                (rainbow-delimiters-depth-4-face (:inherit outline-4))
                (rainbow-delimiters-depth-5-face (:inherit outline-5))
                (rainbow-delimiters-depth-6-face (:inherit outline-6))
                (rainbow-delimiters-depth-7-face (:inherit outline-7))
                (rainbow-delimiters-depth-8-face (:inherit outline-8))
                (rainbow-delimiters-depth-9-face (,@fg-green))
                ;; powerline
                (powerline-active1 (,@fg-base00 :inherit mode-line))
                (powerline-active2 (,@fg-base0 :inherit mode-line))
                (powerline-inactive1 (,@fg-base02 ,@bg-base1 :inherit mode-line-inactive))
                (powerline-inactive2 (,@fg-base01 :inherit mode-line-inactive))
                ;; slime
                (slime-error-face (,@fmt-revr ,@fg-magenta)) ; ErrorMsg
                (slime-note-face (,@fg-yellow))
                (slime-repl-inputted-output-face (,@fg-red))
                (slime-repl-output-mouseover-face (:box (:color base3)))
                (slime-style-warning-face (,@fmt-bold ,@fg-orange))
                (slime-warning-face (,@fmt-bold ,@fg-magenta)) ; WarningMsg
                ;; smartparens
                (sp-pair-overlay-face (,@bg-base02))
                (sp-wrap-overlay-face (,@bg-base02))
                (sp-wrap-tag-overlay-face (,@bg-base02))
                (sp-show-pair-match-face (,@fg-green ,@bg-back))
                (sp-show-pair-mismatch-face (,@bg-magenta ,@fg-base02))
                ;; whitespace
                (whitespace-empty (,@fg-magenta))
                (whitespace-hspace (,@fg-orange))
                (whitespace-indentation (,@fg-base02))
                (whitespace-space (,@fg-base02))
                (whitespace-space-after-tab (,@fg-cyan))
                (whitespace-space-before-tab (,@fmt-bold ,@fg-magenta))
                (whitespace-tab (,@fg-base02))
                (whitespace-trailing (,@fmt-bold ,@fg-magenta ,@bg-base02))
                (whitespace-highlight-face (,@fg-red ,@bg-blue))
                (whitespace-line (,@fg-magenta))
                (whitespace-newline (:inherit shadow :slant normal))
                ;; writegood
                (writegood-weasels-face (,@fmt-curl-cyan ,@fg-cyan))
                (writegood-passive-voice-face (,@fg-magenta))
                (writegood-duplicates-face (:inherit error))
                ;; rcirc
                (rcirc-my-nick (,@fg-blue))
                (rcirc-nick-in-message (,@fg-orange))
                (rcirc-other-nick (,@fg-green))
                (rcirc-prompt (,@fg-yellow))
                (rcirc-bright-nick (,@fg-magenta))
                (rcirc-server (,@fg-base1))
                (rcirc-timestamp (,@fg-base01))
                ;;font-latex
                (font-latex-warning-face (,@fg-red))
                (font-latex-sectioning-5-face (,@fg-violet))
                ;;flyspell
                (flyspell-incorrect (,@fmt-undr-magenta)) ; SpellBad
                (flyspell-duplicate (,@fmt-undr-yellow))
                ;; rst-mode
                (rst-level-1 (:inherit outline-1))
                (rst-level-2 (:inherit outline-2))
                (rst-level-3 (:inherit outline-3))
                (rst-level-4 (:inherit outline-4))
                (rst-level-5 (:inherit outline-5))
                (rst-level-6 (:inherit outline-6))
                ;;ansi-term
                (term-color-black (,@fg-base02 ,@bg-base02))
                (term-color-red (,@fg-red ,@bg-red))
                (term-color-green (,@fg-green ,@bg-green))
                (term-color-yellow (,@fg-yellow ,@bg-yellow))
                (term-color-blue (,@fg-blue ,@bg-blue))
                (term-color-magenta (,@fg-magenta ,@bg-magenta))
                (term-color-cyan (,@fg-cyan ,@bg-cyan))
                (term-color-white (,@fg-base00 ,@bg-base00))
		        ;; tooltip
		        (tooltip (,@bg-base2))
                ;; company
                (company-tooltip (,@fg-base00 ,@bg-base02))
                (company-tooltip-selection (,@fg-green ,@bg-base02))
                (company-tooltip-mouse (,@fg-base1 ,@bg-base02))
                (company-tooltip-common (,@fg-blue ,@bg-base02 ,@fmt-undr))
                (company-tooltip-common-selection (,@fg-green ,@bg-base02 ,@fmt-undr))
                (company-tooltip-annotation (,@fg-yellow ,@bg-base02))
                (company-scrollbar-fg (,@bg-base0))
                (company-scrollbar-bg (,@bg-base02))
                (company-preview (,@bg-green))
                (company-preview-common (,@bg-base02))
                (company-template-field (,@fg-base03 ,@bg-yellow))
                ;; hydra
                (hydra-face-red (,@fmt-bold ,@fg-red))
                (hydra-face-blue (,@fmt-bold ,@fg-blue))
                (hydra-face-amaranth (,@fmt-bold ,@fg-orange))
                (hydra-face-pink (,@fmt-bold ,@fg-magenta))
                (hydra-face-teal (,@fmt-bold ,@fg-cyan))
                ;; guide-key
                (guide-key/prefix-command-face (,@fg-blue))
                (guide-key/highlight-command-face (,@fg-orange))
                (guide-key/key-face (,@fg-green))
                ;; magit
                (magit-log-sha1 (,@fg-red))
                (magit-branch (,@fg-yellow))
                (magit-branch-local (,@fg-cyan))
                (magit-branch-remote (,@fg-green))
                (magit-section-heading (,@fg-yellow))
                (magit-section-highlight (,@bg-base02))
                (magit-tag (,@fg-green))
                (magit-log-author (,@fg-cyan))
                (magit-log-head-label-remote (,@fg-green))
                (magit-log-head-label-tags (,@fg-orange))
                (magit-log-head-label-local (,@fg-yellow))
                (magit-log-head-label-head (,@fg-violet))
                (magit-process-ok (,@fg-green :inherit magit-section-title))
                (magit-process-ng (,@fg-red :inherit magit-section-title))
                ;; undo-tree
                (undo-tree-visualizer-current-face (,@fg-orange))
                (undo-tree-visualizer-default-face (:inherit shadow))
                (undo-tree-visualizer-active-branch-face (:inherit default))
                (undo-tree-visualizer-unmodified-face (,@fg-cyan))
                (undo-tree-visualizer-register-face (,@fg-yellow))
		        ;;visible-mark
		        (visible-mark-active (,@fg-base03 ,@bg-yellow))
                ;; haskell
                (haskell-keyword-face (,@fg-cyan)))))))


;;;###autoload
(when (boundp 'custom-theme-load-path)
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

(defmacro create-lunarized-theme (name description color-definitions)
  `(progn
     (deftheme ,name ,description)
     (apply 'custom-theme-set-faces
            ',name ,color-definitions)
     (provide-theme ',name)))

(provide 'lunarized-definitions)
