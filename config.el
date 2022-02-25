;; In certain modes
(defvar mixed-pitch-modes '(org-mode LaTeX-mode markdown-mode gfm-mode Info-mode)
  "Modes that `mixed-pitch-mode' should be enabled in, but only after UI initialisation.")
(defun init-mixed-pitch-h ()
  "Hook `mixed-pitch-mode' into each mode in `mixed-pitch-modes'.
Also immediately enables `mixed-pitch-modes' if currently in one of the modes."
  (when (memq major-mode mixed-pitch-modes)
    (mixed-pitch-mode 1))
  (dolist (hook mixed-pitch-modes)
    (add-hook (intern (concat (symbol-name hook) "-hook")) #'mixed-pitch-mode)))
(add-hook 'doom-init-ui-hook #'init-mixed-pitch-h)
;; As mixed pitch uses the variable mixed-pitch-face, we can create a new function to apply mixed pitch with a serif face instead of the default. This was created for writeroom mode.
(autoload #'mixed-pitch-serif-mode "mixed-pitch"
  "Change the default face of the current buffer to a serifed variable pitch, while keeping some faces fixed pitch." t)

(after! mixed-pitch
  (defface variable-pitch-serif
    '((t (:family "serif")))
    "A variable-pitch face with serifs."
    :group 'basic-faces)
  (setq mixed-pitch-set-height t)
  (setq variable-pitch-serif-font (font-spec :family "Alegreya" :size 27))
  (set-face-attribute 'variable-pitch-serif nil :font variable-pitch-serif-font)
  (defun mixed-pitch-serif-mode (&optional arg)
    "Change the default face of the current buffer to a serifed variable pitch, while keeping some faces fixed pitch."
    (interactive)
    (let ((mixed-pitch-face 'variable-pitch-serif))
      (mixed-pitch-mode (or arg 'toggle)))))
;; Alegreya ligatures
(set-char-table-range composition-function-table ?f '(["\\(?:ff?[fijlt]\\)" 0 font-shape-gstring]))
(set-char-table-range composition-function-table ?T '(["\\(?:Th\\)" 0 font-shape-gstring]))

(after! marginalia
  (setq marginalia-censor-variables nil)

  (defadvice! +marginalia--anotate-local-file-colorful (cand)
    "Just a more colourful version of `marginalia--anotate-local-file'."
    :override #'marginalia--annotate-local-file
    (when-let (attrs (file-attributes (substitute-in-file-name
                                       (marginalia--full-candidate cand))
                                      'integer))
      (marginalia--fields
       ((marginalia--file-owner attrs)
        :width 12 :face 'marginalia-file-owner)
       ((marginalia--file-modes attrs))
       ((+marginalia-file-size-colorful (file-attribute-size attrs))
        :width 7)
       ((+marginalia--time-colorful (file-attribute-modification-time attrs))
        :width 12))))

  (defun +marginalia--time-colorful (time)
    (let* ((seconds (float-time (time-subtract (current-time) time)))
           (color (doom-blend
                   (face-attribute 'marginalia-date :foreground nil t)
                   (face-attribute 'marginalia-documentation :foreground nil t)
                   (/ 1.0 (log (+ 3 (/ (+ 1 seconds) 345600.0)))))))
      ;; 1 - log(3 + 1/(days + 1)) % grey
      (propertize (marginalia--time time) 'face (list :foreground color))))

  (defun +marginalia-file-size-colorful (size)
    (let* ((size-index (/ (log10 (+ 1 size)) 7.0))
           (color (if (< size-index 10000000) ; 10m
                      (doom-blend 'orange 'green size-index)
                    (doom-blend 'red 'orange (- size-index 1)))))
      (propertize (file-size-human-readable size) 'face (list :foreground color)))))

(setq +zen-text-scale 0.8)
(defvar +zen-serif-p t
  "Whether to use a serifed font with `mixed-pitch-mode'.")
(after! writeroom-mode
  (defvar-local +zen--original-org-indent-mode-p nil)
  (defvar-local +zen--original-mixed-pitch-mode-p nil)
  (defvar-local +zen--original-org-pretty-table-mode-p nil)
  (defun +zen-enable-mixed-pitch-mode-h ()
    "Enable `mixed-pitch-mode' when in `+zen-mixed-pitch-modes'."
    (when (apply #'derived-mode-p +zen-mixed-pitch-modes)
      (if writeroom-mode
          (progn
            (setq +zen--original-mixed-pitch-mode-p mixed-pitch-mode)
            (funcall (if +zen-serif-p #'mixed-pitch-serif-mode #'mixed-pitch-mode) 1))
        (funcall #'mixed-pitch-mode (if +zen--original-mixed-pitch-mode-p 1 -1)))))
  (pushnew! writeroom--local-variables
            'display-line-numbers
            'visual-fill-column-width
            'org-adapt-indentation
            'org-superstar-headline-bullets-list
            'org-superstar-remove-leading-stars)
  (add-hook 'writeroom-mode-enable-hook
            (defun +zen-prose-org-h ()
              "Reformat the current Org buffer appearance for prose."
              (when (eq major-mode 'org-mode)
                (setq display-line-numbers nil
                      visual-fill-column-width 60
                      org-adapt-indentation nil)
                (when (featurep 'org-superstar)
                  (setq-local org-superstar-headline-bullets-list '("⁖" "◉" "○" "✸" "✿")
                              ;; org-superstar-headline-bullets-list '("🙐" "🙑" "🙒" "🙓" "🙔" "🙕" "🙖" "🙗")
                              org-superstar-remove-leading-stars t)
                  (org-superstar-restart))
                (setq
                 +zen--original-org-indent-mode-p org-indent-mode)
                 +zen--original-org-pretty-table-mode-p (bound-and-true-p org-pretty-table-mode))
                (org-indent-mode -1)
                (org-pretty-table-mode 1))))
  (add-hook 'writeroom-mode-disable-hook
            (defun +zen-nonprose-org-h ()
              "Reverse the effect of `+zen-prose-org'."
              (when (eq major-mode 'org-mode)
                (when (featurep 'org-superstar)
                  (org-superstar-restart))
                (when +zen--original-org-indent-mode-p (org-indent-mode 1)
;;                 (unless +zen--original-org-pretty-table-mode-p (org-pretty-table-mode -1))
                ))))

;; Set the system-time-locale to "C" to always display days in English (See Stackoverflow: "emacs org-mode language of time stamps")
(setq system-time-locale "C")
;; Info Path needed to be set because Info files where not correctly located
(add-hook 'Info-mode-hook
          (lambda ()
(add-to-list 'Info-default-directory-list "c:/Program Files/Emacs/emacs-28.0.91/share/info")
(setq Info-directory-list '("c:/Program Files/Emacs/emacs-28.0.91/share/info"))
))
;; Coding-System Stackoverflow questions: 2901541
  (set-language-environment 'utf-8)
  (setq locale-coding-system 'utf-8)
  (set-default-coding-systems 'utf-8)
  (set-terminal-coding-system 'utf-8)
  (set-selection-coding-system
    (if (eq system-type 'windows-nt)
        'utf-16-le  ;; https://rufflewind.com/2014-07-20/pasting-unicode-in-emacs-on-windows
      'utf-8))
  (prefer-coding-system 'utf-8)
;; Coming to terms with Yanking & killing text with other apps (maybe one day)
(setq save-interprogram-paste-before-kill t) ;; preventing to loose old clipboard data
(setq select-enable-clipboard t) ;; Better safe than sorry
;; Becon - Never lose your cursor again (malabarba@github.com)
(beacon-mode 1)
;; Smart parentheses (remind me of the SBB)
(sp-local-pair
 '(org-mode)
 "<<" ">>"
 :actions '(insert))

;; My spelling bee is ispell - not for now - at least
;; Hook flyspell - Not so fast, since I'm mainly writing German.
;; (add-hook 'org-mode-hook 'turn-on-flyspell)
;; In planitext
;;(set-company-backend!
;;  '(text-mode
;;    markdown-mode
;;    gfm-mode)
;;  '(:seperate
;;    company-ispell
;;    company-files
;;    company-yasnippet))
;; Dictionary
;; (setq ispell-dictionary "en-custom")
;; Ahem, my guess is, this is where the personal dictionary goes
;; (partly) Not setup yet
;;(setq ispell-personal-dictionary (expand-file-name ".ispell_personal" doom-private-dir))
;;      ispell-alternate-dictionary)

;; Tecosaur: visual-line-mode might mess with tables
;; Can't accept that (me)
;;(remove-hook 'text-mode-hook #'visual-line-mode)
;;(add-hook 'text-mode-hook #'auto-fill-mode)
;; Toggle Calibre
(map! :leader
      :desc "CalibreDB"
      "t C" #'calibredb)
;; Toggle buffer follow mode
(map! :leader
      :desc "Follow Mode"
      "b f" #'follow-mode)
(setq custom-file null-device
      delete-by-moving-to-trash t
      undo-limit 80000000
      evil-want-fine-undo t
      auto-save-default t
      scroll-margin 2)
      (display-time-mode 1)
;;      (unless (string-match-p "^Power N/A" (battery))
      (display-battery-mode 1)
;; Window and buffer management
(setq evil-vsplit-window-right t
      evil-split-window-below t)
(defadvice! prompt-for-buffer (&rest _)
  :after '(evil-window-split evil-window-vsplit)
  (consult-buffer))
(setq-default
       ;; Take window space from all other windows
      window-combination-resize t
      x-stretch-cursor t)
;; Tecosau wan't to make my vompletion with vertico nicer
(after! marginalia
  (setq marginalia-censor-variables nil)

  (defadvice! +marginalia--anotate-local-file-colorful (cand)
    "Just a more colourful version of `marginalia--anotate-local-file'."
    :override #'marginalia--annotate-local-file
    (when-let (attrs (file-attributes (substitute-in-file-name
                                       (marginalia--full-candidate cand))
                                      'integer))
      (marginalia--fields
       ((marginalia--file-owner attrs)
        :width 12 :face 'marginalia-file-owner)
       ((marginalia--file-modes attrs))
       ((+marginalia-file-size-colorful (file-attribute-size attrs))
        :width 7)
       ((+marginalia--time-colorful (file-attribute-modification-time attrs))
        :width 12))))

  (defun +marginalia--time-colorful (time)
    (let* ((seconds (float-time (time-subtract (current-time) time)))
           (color (doom-blend
                   (face-attribute 'marginalia-date :foreground nil t)
                   (face-attribute 'marginalia-documentation :foreground nil t)
                   (/ 1.0 (log (+ 3 (/ (+ 1 seconds) 345600.0)))))))
      ;; 1 - log(3 + 1/(days + 1)) % grey
      (propertize (marginalia--time time) 'face (list :foreground color))))

  (defun +marginalia-file-size-colorful (size)
    (let* ((size-index (/ (log10 (+ 1 size)) 7.0))
           (color (if (< size-index 10000000) ; 10m
                      (doom-blend 'orange 'green size-index)
                    (doom-blend 'red 'orange (- size-index 1)))))
      (propertize (file-size-human-readable size) 'face (list :foreground color)))))

(use-package! info-colors
  :commands (info-colors-fontify-node))

(add-hook 'Info-selection-hook 'info-colors-fontify-node)

(add-to-list 'initial-frame-alist '(fullscreen . maximized))
;; (set-frame-parameter (selected-frame) 'alpha '(95 50))

;; Jump in with leader + W
(map! :leader
 (:prefix ("W" . "org-web")
      :desc "Link-For-URL"
      "l" #'org-web-tools-insert-link-for-url
      :leader
      :desc "Web-Page-As-Entry"
      "w" #'org-web-tools-insert-web-page-as-entry
      :leader
      :desc "Read-Url-As-Org"
      "r" #'org-web-tools-read-url-as-org)
 )

(map! :leader
      :desc "Dired"
      "d d" #'dired
      :leader
      :desc "Dired jump to current"
      "d j" #'dired-jump
      (:after dired
       (:map dired-mode-map
        :leader
        :desc "Peep-dired image previews"
        "d p" #'peep-dired
        :leader
        :desc "Dired view file"
        "d v" #'dired-view-file)))
;; Make 'h' and 'l' go back and forward in dired. Much faster to navigate the directory structure!
(evil-define-key 'normal dired-mode-map
  (kbd "h") 'dired-up-directory
  (kbd "l") 'dired-open-file) ; use dired-find-file instead if not using dired-open package
;; If peep-dired is enabled, you will get image previews as you go up/down with 'j' and 'k'
(evil-define-key 'normal peep-dired-mode-map
  (kbd "j") 'peep-dired-next-file
  (kbd "k") 'peep-dired-prev-file)
(add-hook 'peep-dired-hook 'evil-normalize-keymaps)
;; Get file icons in dired
(add-hook 'dired-mode-hook 'all-the-icons-dired-mode)
;; With dired-open plugin, you can launch external programs for certain extensions
;; For example, I set all .png files to open in 'sxiv' and all .mp4 files to open in 'mpv'
(setq dired-open-extensions '(("gif" . "sxiv")
                              ("jpg" . "sxiv")
                              ("png" . "sxiv")
                              ("mkv" . "mpv")
                              ("mp4" . "mpv")))
(after! dired
  (setq dired-listing-switches "-agho --group-directories-first")
  )

(setq browse-url-browser-function 'eww-browse-url)
(map! :leader
      :desc "Eww web browser"
      "e w" #'eww
      :leader
      :desc "Eww reload page"
      "e R" #'eww-reload
      :leader
      :desc "Search web for text between BEG/END"
      "s w" #'eww-search-words)

;; Tecosaur font & pitch attitutes
(defvar mixed-pitch-modes '(org-mode LaTeX-mode markdown-mode gfm-mode Info-mode)
  "Modes that `mixed-pitch-mode' should be enabled in, but only after UI initialisation.")
(defun init-mixed-pitch-h ()
  "Hook `mixed-pitch-mode' into each mode in `mixed-pitch-modes'.
Also immediately enables `mixed-pitch-modes' if currently in one of the modes."
  (when (memq major-mode mixed-pitch-modes)
    (mixed-pitch-mode 1))
  (dolist (hook mixed-pitch-modes)
    (add-hook (intern (concat (symbol-name hook) "-hook")) #'mixed-pitch-mode)))
(add-hook 'doom-init-ui-hook #'init-mixed-pitch-h)
;; Apply Serif to mixed-pitch fonts
(autoload #'mixed-pitch-serif-mode "mixed-pitch"
  "Change the default face of the current buffer to a serifed variable pitch, while keeping some faces fixed pitch." t)
(after! mixed-pitch
  (defface variable-pitch-serif
    '((t (:family "serif")))
    "A variable-pitch face with serifs."
    :group 'basic-faces)
  (setq mixed-pitch-set-height t)
  (setq variable-pitch-serif-font (font-spec :family "Alegreya" :size 22))
  (set-face-attribute 'variable-pitch-serif nil :font variable-pitch-serif-font)
  (defun mixed-pitch-serif-mode (&optional arg)
    "Change the default face of the current buffer to a serifed variable pitch, while keeping some faces fixed pitch."
    (interactive)
    (let ((mixed-pitch-face 'variable-pitch-serif))
      (mixed-pitch-mode (or arg 'toggle)))))
;; Set specific 😉 font
;; font for all unicode characters
(set-fontset-font t 'unicode "Symbola" nil 'prepend)
;; While we are at it (look up Native Emojies @Reddit)
(set-fontset-font t 'symbol "BabelStone Flags")
(set-fontset-font t 'symbol "Twitter Color Emoji")
(set-fontset-font t 'symbol "Noto Color Emoji" nil 'append)
(set-fontset-font t 'symbol "Noto Emoji" nil 'append)
(set-fontset-font t 'symbol "Twemoji" nil 'append)
(set-fontset-font t 'symbol "STIX Two Math" nil 'append)
(set-fontset-font t 'symbol "Euclid Math One" nil 'append)
(set-fontset-font t 'symbol "Euclid Math Two" nil 'append)
(set-fontset-font t 'symbol "Noto Sans Math" nil 'append)
;; Font-Face
(setq doom-font (font-spec :family "JetBrains Mono" :size 14)
      doom-big-font (font-spec :family "JetBrains Mono" :size 18)
      doom-variable-pitch-font (font-spec :family "Overpass" :size 14)
;;      doom-unicode-font (font-spec :family "JuliaMono")
      doom-serif-font (font-spec :family "IBM Plex Mono" :weight 'light))

;;Hook Olivetti to text-mode
(add-hook 'text-mode-hook #'olivetti-mode)
(map! :leader
 (:prefix ("b v" . "Olivetti")
      :desc "Toggle Olivetti"
      "o" #'olivetti-mode
      :leader
      :desc "Set-Width"
      "r" #'olivetti-set-width))

;; I don't trust too pretty (see other references as well)
(add-hook 'org-mode-hook #'+org-pretty-mode)
(custom-set-faces!
  '(outline-1 :weight extra-bold :height 1.25)
  '(outline-2 :weight bold :height 1.15)
  '(outline-3 :weight bold :height 1.12)
  '(outline-4 :weight semi-bold :height 1.09)
  '(outline-5 :weight semi-bold :height 1.06)
  '(outline-6 :weight semi-bold :height 1.03)
  '(outline-8 :weight semi-bold)
  '(outline-9 :weight semi-bold))
;; Try to let the Leuven theme do the headings!
;;(custom-set-faces!
;;  '(org-document-title :height 1.2))
;; Error face for deadlines
(setq org-agenda-deadline-faces
      '((1.001 . error)
        (1.0 . org-warning)
        (0.5 . org-upcoming-deadline)
        (0.0 . org-upcoming-distant-deadline)))
;; Quotes
(setq org-fontify-quote-and-verse-blocks t)
;; Speed up org-mode typing
;; Since trowing many errors
;;(defun locally-defer-font-lock ()
;;  "Set jit-lock defer and stealth, when buffer is over a certain size."
;;  (when (> (buffer-size) 50000)
;;    (setq-local jit-lock-defer-time 0.05
;;                jit-lock-stealth-time 1)))

;; See the above deactivated jit-lock block
;;(add-hook 'org-mode-hook #'locally-defer-font-lock)
;; org inlinine src blocks
(defvar org-prettify-inline-results t
  "Whether to use (ab)use prettify-symbols-mode on {{{results(...)}}}.
Either t or a cons cell of strings which are used as substitutions
for the start and end of inline results, respectively.")

(defvar org-fontify-inline-src-blocks-max-length 200
  "Maximum content length of an inline src block that will be fontified.")

(defun org-fontify-inline-src-blocks (limit)
  "Try to apply `org-fontify-inline-src-blocks-1'."
  (condition-case nil
      (org-fontify-inline-src-blocks-1 limit)
    (error (message "Org mode fontification error in %S at %d"
                    (current-buffer)
                    (line-number-at-pos)))))

(defun org-fontify-inline-src-blocks-1 (limit)
  "Fontify inline src_LANG blocks, from `point' up to LIMIT."
  (let ((case-fold-search t)
        (initial-point (point)))
    (while (re-search-forward "\\_<src_\\([^ \t\n[{]+\\)[{[]?" limit t) ; stolen from `org-element-inline-src-block-parser'
      (let ((beg (match-beginning 0))
            pt
            (lang-beg (match-beginning 1))
            (lang-end (match-end 1)))
        (remove-text-properties beg lang-end '(face nil))
        (font-lock-append-text-property lang-beg lang-end 'face 'org-meta-line)
        (font-lock-append-text-property beg lang-beg 'face 'shadow)
        (font-lock-append-text-property beg lang-end 'face 'org-block)
        (setq pt (goto-char lang-end))
        ;; `org-element--parse-paired-brackets' doesn't take a limit, so to
        ;; prevent it searching the entire rest of the buffer we temporarily
        ;; narrow the active region.
        (save-restriction
          (narrow-to-region beg (min (point-max) limit (+ lang-end org-fontify-inline-src-blocks-max-length)))
          (when (ignore-errors (org-element--parse-paired-brackets ?\[))
            (remove-text-properties pt (point) '(face nil))
            (font-lock-append-text-property pt (point) 'face 'org-block)
            (setq pt (point)))
          (when (ignore-errors (org-element--parse-paired-brackets ?\{))
            (remove-text-properties pt (point) '(face nil))
            (font-lock-append-text-property pt (1+ pt) 'face '(org-block shadow))
            (unless (= (1+ pt) (1- (point)))
              (if org-src-fontify-natively
                  (org-src-font-lock-fontify-block (buffer-substring-no-properties lang-beg lang-end) (1+ pt) (1- (point)))
                (font-lock-append-text-property (1+ pt) (1- (point)) 'face 'org-block)))
            (font-lock-append-text-property (1- (point)) (point) 'face '(org-block shadow))
            (setq pt (point))))
        (when (and org-prettify-inline-results (re-search-forward "\\= {{{results(" limit t))
          (font-lock-append-text-property pt (1+ pt) 'face 'org-block)
          (goto-char pt))))
    (when org-prettify-inline-results
      (goto-char initial-point)
      (org-fontify-inline-src-results limit))))

(defun org-fontify-inline-src-results (limit)
  (while (re-search-forward "{{{results(\\(.+?\\))}}}" limit t)
    (remove-list-of-text-properties (match-beginning 0) (point)
                                    '(composition
                                      prettify-symbols-start
                                      prettify-symbols-end))
    (font-lock-append-text-property (match-beginning 0) (match-end 0) 'face 'org-block)
    (let ((start (match-beginning 0)) (end (match-beginning 1)))
      (with-silent-modifications
        (compose-region start end (if (eq org-prettify-inline-results t) "⟨" (car org-prettify-inline-results)))
        (add-text-properties start end `(prettify-symbols-start ,start prettify-symbols-end ,end))))
    (let ((start (match-end 1)) (end (point)))
      (with-silent-modifications
        (compose-region start end (if (eq org-prettify-inline-results t) "⟩" (cdr org-prettify-inline-results)))
        (add-text-properties start end `(prettify-symbols-start ,start prettify-symbols-end ,end))))))

(defun org-fontify-inline-src-blocks-enable ()
  "Add inline src fontification to font-lock in Org.
Must be run as part of `org-font-lock-set-keywords-hook'."
  (setq org-font-lock-extra-keywords
        (append org-font-lock-extra-keywords '((org-fontify-inline-src-blocks)))))

(add-hook 'org-font-lock-set-keywords-hook #'org-fontify-inline-src-blocks-enable)

;; Unicode for checkboxes and other stuff
(after! org-superstar
  (setq org-superstar-headline-bullets-list '("⁖" "◉" "○" "✸" "✿" "✤" "✜" "◆" "▶")
        org-superstar-prettify-item-bullets t ))

(setq org-ellipsis " ▾ "
      org-hide-leading-stars t
      org-priority-highest ?A
      org-priority-lowest ?E
      org-priority-faces
      '((?A . 'all-the-icons-red)
        (?B . 'all-the-icons-orange)
        (?C . 'all-the-icons-yellow)
        (?D . 'all-the-icons-green)
        (?E . 'all-the-icons-blue)))

(appendq! +ligatures-extra-symbols
          `(:checkbox      "☐"
            :pending       "◼"
            :checkedbox    "☑"
            :list_property "∷"
            :em_dash       "—"
            :ellipses      "…"
            :arrow_right   "→"
            :arrow_left    "←"
            :title         "𝙏"
            :subtitle      "𝙩"
            :author        "𝘼"
            :date          "𝘿"
            :property      "☸"
            :options       "⌥"
            :startup       "⏻"
            :macro         "𝓜"
            :html_head     "🅷"
            :html          "🅗"
            :latex_class   "🄻"
            :latex_header  "🅻"
            :beamer_header "🅑"
            :latex         "🅛"
            :attr_latex    "🄛"
            :attr_html     "🄗"
            :attr_org      "⒪"
            :begin_quote   "❝"
            :end_quote     "❞"
            :caption       "☰"
            :header        "›"
            :results       "🠶"
            :begin_export  "⏩"
            :end_export    "⏪"
            :properties    "⚙"
            :end           "∎"
            :priority_a   ,(propertize "⚑" 'face 'all-the-icons-red)
            :priority_b   ,(propertize "⬆" 'face 'all-the-icons-orange)
            :priority_c   ,(propertize "■" 'face 'all-the-icons-yellow)
            :priority_d   ,(propertize "⬇" 'face 'all-the-icons-green)
            :priority_e   ,(propertize "❓" 'face 'all-the-icons-blue)))
(set-ligatures! 'org-mode
  :merge t
  :checkbox      "[ ]"
  :pending       "[-]"
  :checkedbox    "[X]"
  :list_property "::"
  :em_dash       "---"
  :ellipsis      "..."
  :arrow_right   "->"
  :arrow_left    "<-"
  :title         "#+title:"
  :subtitle      "#+subtitle:"
  :author        "#+author:"
  :date          "#+date:"
  :property      "#+property:"
  :options       "#+options:"
  :startup       "#+startup:"
  :macro         "#+macro:"
  :html_head     "#+html_head:"
  :html          "#+html:"
  :latex_class   "#+latex_class:"
  :latex_header  "#+latex_header:"
  :beamer_header "#+beamer_header:"
  :latex         "#+latex:"
  :attr_latex    "#+attr_latex:"
  :attr_html     "#+attr_html:"
  :attr_org      "#+attr_org:"
  :begin_quote   "#+begin_quote"
  :end_quote     "#+end_quote"
  :caption       "#+caption:"
  :header        "#+header:"
  :begin_export  "#+begin_export"
  :end_export    "#+end_export"
  :results       "#+RESULTS:"
  :property      ":PROPERTIES:"
  :end           ":END:"
  :priority_a    "[#A]"
  :priority_b    "[#B]"
  :priority_c    "[#C]"
  :priority_d    "[#D]"
  :priority_e    "[#E]")
(plist-put +ligatures-extra-symbols :name "⁍")

(setq emojify-emoji-set "twemoji-v2")
(defvar emojify-disabled-emojis
  '(;; Org
    "◼" "☑" "☸" "✅" "⚙" "⏩" "⏪" "⬆" "⬇" "❓"
    ;; Terminal powerline
    "✔"
    ;; Box drawing
    "▶" "◀")
  "Characters that should never be affected by `emojify-mode'.")
(defadvice! emojify-delete-from-data ()
  "Ensure `emojify-disabled-emojis' don't appear in `emojify-emojis'."
  :after #'emojify-set-emoji-data
  (dolist (emoji emojify-disabled-emojis)
    (remhash emoji emojify-emojis)))
;; Replace typed ascii emojis with unicode emojis
(defun emojify--replace-text-with-emoji (orig-fn emoji text buffer start end &optional target)
  "Modify `emojify--propertize-text-for-emoji' to replace ascii/github emoticons with unicode emojis, on the fly."
  (if (or (not emoticon-to-emoji) (= 1 (length text)))
      (funcall orig-fn emoji text buffer start end target)
    (delete-region start end)
    (insert (ht-get emoji "unicode"))))

(define-minor-mode emoticon-to-emoji
  "Write ascii/gh emojis, and have them converted to unicode live."
  :global nil
  :init-value nil
  (if emoticon-to-emoji
      (progn
        (setq-local emojify-emoji-styles '(ascii github unicode))
        (advice-add 'emojify--propertize-text-for-emoji :around #'emojify--replace-text-with-emoji)
        (unless emojify-mode
          (emojify-turn-on-emojify-mode)))
    (setq-local emojify-emoji-styles (default-value 'emojify-emoji-styles))
    (advice-remove 'emojify--propertize-text-for-emoji #'emojify--replace-text-with-emoji)))

(setq display-line-numbers-type 'relative)
(map! :leader
      :desc "Toggle truncate lines"
      "t t" #'toggle-truncate-lines)

;; Disable line numbers for some modes
(dolist (mode '(org-mode-hook
                term-mode-hook
                eshell-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode 0))))

;; (setq doom-theme 'doom-dracula)
;; LEUVEN Theme by github.com/fniessen
;; Fontify code in blocks in code blocks
(setq doom-theme 'leuven)
(after! org
  (setq org-src-fontify-natively t)
  ;; Fontify the whole line for headings (with a background color).
  (setq org-fontify-whole-heading-line t)
  ;; Faces for specific TODO keywords.
  (setq org-todo-keyword-faces
        '(("WAIT" . leuven-org-waiting-for-kwd)))
  ;; Mode-line colors
  ;; Org non-standard faces.
  (defface leuven-org-waiting-for-kwd
    '((t :weight bold :box "#89C58F"
         :foreground "#89C58F" :background "#E2FEDE"))
    "Face used to display state WAIT.")
;;  (defface mode-line
;;    '((t (:box (:line-width 1 :color "#1A2F54") :foreground "green" :background "DarkOrange")))
;;    "Orange and green colors in mode-line.")
  )

(map! :leader
      :desc "Annotation-Mode"
      "t A" #'annotate-mode)
(map! :leader
 (:prefix ("A" . "annotations")
      :desc "Annote me"
      "a" #'annotate-annotate
      :leader
      :desc "Refresh"
      "r" #'annotate-load-annotations))

(map! :leader
      :desc "XWidget Browser" "o x" #'xwidget-webkit-browse-url)

(map! :leader
      :desc "Copy to register"
      "r c" #'copy-to-register
      :leader
      :desc "Frameset to register"
      "r f" #'frameset-to-register
      :leader
      :desc "Insert contents of register"
      "r i" #'insert-register
      :leader
      :desc "Jump to register"
      "r j" #'jump-to-register
      :leader
      :desc "List registers"
      "r l" #'list-registers
      :leader
      :desc "Number to register"
      "r n" #'number-to-register
      :leader
      :desc "Interactively choose a register"
      "r r" #'counsel-register
      :leader
      :desc "View a register"
      "r v" #'view-register
      :leader
      :desc "Window configuration to register"
      "r w" #'window-configuration-to-register
      :leader
      :desc "Increment register"
      "r +" #'increment-register
      :leader
      :desc "Point to register"
      "r SPC" #'point-to-register)

(after! org
        (require 'org-bullets)  ; Nicer bullets in org-mode
        (add-hook 'org-mode-hook (lambda () (org-bullets-mode 1)))
        (add-to-list 'auto-mode-alist '("\.\(org\|agenda_files\|txt\)$" . org-mode))
        (setq org-directory "~/kDrive/BC/Emacs/org/"
              +org-capture-journal-file "~/kDrive/BC/Emacs/org/journal.org"
              org-use-property-inheritance t
              org-catch-invisible-edits 'smart
              org-default-notes-file (expand-file-name "notes.org" org-directory)
              org-list-allow-alphabetical t ;; Alphabetical counters like "[@c]" will be recognized.
              org-agenda-files (directory-files-recursively "~/kDrive/BC/Emacs/org/" "\\.org$")
              org-refile-allow-creating-parent-nodes 'confirm
              org-ellipsis " ▼ "
              org-log-done 'time
              org-journal-dir "~/kDrive/BC/Emacs/org/"
              org-startup-folded t
              org-journal-date-format "%B %d, %Y (%A)"
              org-journal-file-format "%Y-%m-%d"
              org-hide-emphasis-markers t
              ;; ex. of org-link-abbrev-alist in action
              ;; [[arch-wiki:Name_of_Page][Description]]
              org-link-abbrev-alist    ; This overwrites the default Doom org-link-abbrev-list
              '(("google" . "http://www.google.com/search?q=")
                ("arch-wiki" . "https://wiki.archlinux.org/index.php/")
                ("ddg" . "https://duckduckgo.com/?q=")
                ("wiki" . "https://en.wikipedia.org/wiki/"))
              org-todo-keywords        ; This overwrites the default Doom org-todo-keywords
              '((sequence
                 "TODO(t)"           ; A task that is ready to be tackled
                 "ONIT(o)"
                 "NEXT(n)"
                 "PROJ(p)"           ; A project that contains other tasks
                 "MEET(m)"
                 "WAIT(w@/!)"           ; Something is holding up this task
                 "|"                 ; The pipe necessary to separate "active" states and "inactive" states
                 "DONE(d)"           ; Task has been completed
                 "CANCL(c@/!)" )))) ; Task has been cancelled

(map! :map evil-org-mode-map
      :after evil-org
      :n "g k" #'org-previous-visible-heading
      :n "g j" #'org-next-visible-heading)

;; Declarative Org Capture Templates makes nicer setups for org-capture
(use-package! doct
  :commands doct)
(after! org-capture

  (defun +doct-icon-declaration-to-icon (declaration)
    "Convert :icon declaration to icon"
    (let ((name (pop declaration))
          (set  (intern (concat "all-the-icons-" (plist-get declaration :set))))
          (face (intern (concat "all-the-icons-" (plist-get declaration :color))))
          (v-adjust (or (plist-get declaration :v-adjust) 0.01)))
      (apply set `(,name :face ,face :v-adjust ,v-adjust))))

  (defun +doct-iconify-capture-templates (groups)
    "Add declaration's :icon to each template group in GROUPS."
    (let ((templates (doct-flatten-lists-in groups)))
      (setq doct-templates (mapcar (lambda (template)
                                     (when-let* ((props (nthcdr (if (= (length template) 4) 2 5) template))
                                                 (spec (plist-get (plist-get props :doct) :icon)))
                                       (setf (nth 1 template) (concat (+doct-icon-declaration-to-icon spec)
                                                                      "\t"
                                                                      (nth 1 template))))
                                     template)
                                   templates))))

  (setq doct-after-conversion-functions '(+doct-iconify-capture-templates))

  (defvar +org-capture-recipies  "~/kDrive/BC/Emacs/org/recipies.org")

  (defun set-org-capture-templates ()
    (setq org-capture-templates
          (doct `(("Personal todo" :keys "t"
                   :icon ("checklist" :set "octicon" :color "green")
                   :file +org-capture-todo-file
                   :prepend t
                   :headline "Inbox"
                   :type entry
                   :template ("* TODO %?"
                              "%i %a")
                   )
                  ("Email" :keys "e"
                   :icon ("envelope" :set "faicon" :color "blue")
                   :file +org-capture-todo-file
                   :prepend t
                   :headline "Inbox"
                   :type entry
                   :template ("* TODO %^{type|reply to|contact} %\\3 %? :email:"
                              "Send an email %^{urgancy|soon|ASAP|anon|at some point|eventually} to %^{recipiant}"
                              "about %^{topic}"
                              "%U %i %a"))
                  ("Interesting" :keys "i"
                   :icon ("eye" :set "faicon" :color "lcyan")
                   :file +org-capture-todo-file
                   :prepend t
                   :headline "Interesting"
                   :type entry
                   :template ("* [ ] %{desc}%? :%{i-type}:"
                              "%i %a")
                   :children (("Webpage" :keys "w"
                               :icon ("globe" :set "faicon" :color "green")
                               :desc "%(org-cliplink-capture) "
                               :i-type "read:web"
                               )
                              ("Article" :keys "a"
                               :icon ("file-text" :set "octicon" :color "yellow")
                               :desc ""
                               :i-type "read:reaserch"
                               )
                              ("\tRecipie" :keys "r"
                               :icon ("spoon" :set "faicon" :color "dorange")
                               :file +org-capture-recipies
                               :headline "Unsorted"
                               :template "%(org-chef-get-recipe-from-url)"
                               )
                              ("Information" :keys "i"
                               :icon ("info-circle" :set "faicon" :color "blue")
                               :desc ""
                               :i-type "read:info"
                               )
                              ("Idea" :keys "I"
                               :icon ("bubble_chart" :set "material" :color "silver")
                               :desc ""
                               :i-type "idea"
                               )))
                  ("Tasks" :keys "k"
                   :icon ("inbox" :set "octicon" :color "yellow")
                   :file +org-capture-todo-file
                   :prepend t
                   :headline "Tasks"
                   :type entry
                   :template ("* notdo %? %^G %{extra}"
                              "%i %a")
                   :children (("General Task" :keys "k"
                               :icon ("inbox" :set "octicon" :color "yellow")
                               :extra ""
                               )
                              ("Task with deadline" :keys "d"
                               :icon ("timer" :set "material" :color "orange" :v-adjust -0.1)
                               :extra "\nDEADLINE: %^{Deadline:}"
                               )
                              ("Scheduled Task" :keys "s"
                               :icon ("calendar" :set "octicon" :color "orange")
                               :extra "\nSCHEDULED: %^{Start time:}"
                               )
                              ))
                  ("Project" :keys "p"
                   :icon ("repo" :set "octicon" :color "silver")
                   :prepend t
                   :type entry
                   :headline "Inbox"
                   :template ("* %{time-or-todo} %?"
                              "%i"
                              "%a")
                   :file ""
                   :custom (:time-or-todo "")
                   :children (("Project-local todo" :keys "t"
                               :icon ("checklist" :set "octicon" :color "green")
                               :time-or-todo "TODO"
                               :file +org-capture-project-todo-file)
                              ("Project-local note" :keys "n"
                               :icon ("sticky-note" :set "faicon" :color "yellow")
                               :time-or-todo "%U"
                               :file +org-capture-project-notes-file)
                              ("Project-local changelog" :keys "c"
                               :icon ("list" :set "faicon" :color "blue")
                               :time-or-todo "%U"
                               :heading "Unreleased"
                               :file +org-capture-project-changelog-file))
                   )
                  ("\tCentralised project templates"
                   :keys "o"
                   :type entry
                   :prepend t
                   :template ("* %{time-or-todo} %?"
                              "%i"
                              "%a")
                   :children (("Project todo"
                               :keys "t"
                               :prepend nil
                               :time-or-todo "TODO"
                               :heading "Tasks"
                               :file +org-capture-central-project-todo-file)
                              ("Project note"
                               :keys "n"
                               :time-or-todo "%U"
                               :heading "Notes"
                               :file +org-capture-central-project-notes-file)
                              ("Project changelog"
                               :keys "c"
                               :time-or-todo "%U"
                               :heading "Unreleased"
                               :file +org-capture-central-project-changelog-file))
                   )))))

  (set-org-capture-templates)
  (unless (display-graphic-p)
    (add-hook 'server-after-make-frame-hook
              (defun org-capture-reinitialise-hook ()
                (when (display-graphic-p)
                  (set-org-capture-templates)
                  (remove-hook 'server-after-make-frame-hook
                               #'org-capture-reinitialise-hook))))))


;; Improve the capture dialogue looks
(defun org-capture-select-template-prettier (&optional keys)
  "Select a capture template, in a prettier way than default
Lisp programs can force the template by setting KEYS to a string."
  (let ((org-capture-templates
         (or (org-contextualize-keys
              (org-capture-upgrade-templates org-capture-templates)
              org-capture-templates-contexts)
             '(("t" "Task" entry (file+headline "" "Tasks")
                "* TODO %?\n  %u\n  %a")))))
    (if keys
        (or (assoc keys org-capture-templates)
            (error "No capture template referred to by \"%s\" keys" keys))
      (org-mks org-capture-templates
               "Select a capture template\n━━━━━━━━━━━━━━━━━━━━━━━━━"
               "Template key: "
               `(("q" ,(concat (all-the-icons-octicon "stop" :face 'all-the-icons-red :v-adjust 0.01) "\tAbort")))))))
(advice-add 'org-capture-select-template :override #'org-capture-select-template-prettier)

(defun org-mks-pretty (table title &optional prompt specials)
  "Select a member of an alist with multiple keys. Prettified.

TABLE is the alist which should contain entries where the car is a string.
There should be two types of entries.

1. prefix descriptions like (\"a\" \"Description\")
   This indicates that `a' is a prefix key for multi-letter selection, and
   that there are entries following with keys like \"ab\", \"ax\"…

2. Select-able members must have more than two elements, with the first
   being the string of keys that lead to selecting it, and the second a
   short description string of the item.

The command will then make a temporary buffer listing all entries
that can be selected with a single key, and all the single key
prefixes.  When you press the key for a single-letter entry, it is selected.
When you press a prefix key, the commands (and maybe further prefixes)
under this key will be shown and offered for selection.

TITLE will be placed over the selection in the temporary buffer,
PROMPT will be used when prompting for a key.  SPECIALS is an
alist with (\"key\" \"description\") entries.  When one of these
is selected, only the bare key is returned."
  (save-window-excursion
    (let ((inhibit-quit t)
          (buffer (org-switch-to-buffer-other-window "*Org Select*"))
          (prompt (or prompt "Select: "))
          case-fold-search
          current)
      (unwind-protect
          (catch 'exit
            (while t
              (setq-local evil-normal-state-cursor (list nil))
              (erase-buffer)
              (insert title "\n\n")
              (let ((des-keys nil)
                    (allowed-keys '("\C-g"))
                    (tab-alternatives '("\s" "\t" "\r"))
                    (cursor-type nil))
                ;; Populate allowed keys and descriptions keys
                ;; available with CURRENT selector.
                (let ((re (format "\\`%s\\(.\\)\\'"
                                  (if current (regexp-quote current) "")))
                      (prefix (if current (concat current " ") "")))
                  (dolist (entry table)
                    (pcase entry
                      ;; Description.
                      (`(,(and key (pred (string-match re))) ,desc)
                       (let ((k (match-string 1 key)))
                         (push k des-keys)
                         ;; Keys ending in tab, space or RET are equivalent.
                         (if (member k tab-alternatives)
                             (push "\t" allowed-keys)
                           (push k allowed-keys))
                         (insert (propertize prefix 'face 'font-lock-comment-face) (propertize k 'face 'bold) (propertize "›" 'face 'font-lock-comment-face) "  " desc "…" "\n")))
                      ;; Usable entry.
                      (`(,(and key (pred (string-match re))) ,desc . ,_)
                       (let ((k (match-string 1 key)))
                         (insert (propertize prefix 'face 'font-lock-comment-face) (propertize k 'face 'bold) "   " desc "\n")
                         (push k allowed-keys)))
                      (_ nil))))
                ;; Insert special entries, if any.
                (when specials
                  (insert "─────────────────────────\n")
                  (pcase-dolist (`(,key ,description) specials)
                    (insert (format "%s   %s\n" (propertize key 'face '(bold all-the-icons-red)) description))
                    (push key allowed-keys)))
                ;; Display UI and let user select an entry or
                ;; a sub-level prefix.
                (goto-char (point-min))
                (unless (pos-visible-in-window-p (point-max))
                  (org-fit-window-to-buffer))
                (let ((pressed (org--mks-read-key allowed-keys
                                                  prompt
                                                  (not (pos-visible-in-window-p (1- (point-max)))))))
                  (setq current (concat current pressed))
                  (cond
                   ((equal pressed "\C-g") (user-error "Abort"))
                   ;; Selection is a prefix: open a new menu.
                   ((member pressed des-keys))
                   ;; Selection matches an association: return it.
                   ((let ((entry (assoc current table)))
                      (and entry (throw 'exit entry))))
                   ;; Selection matches a special entry: return the
                   ;; selection prefix.
                   ((assoc current specials) (throw 'exit current))
                   (t (error "No entry available")))))))
        (when buffer (kill-buffer buffer))))))
(advice-add 'org-mks :override #'org-mks-pretty)
;; even prettier now
(setf (alist-get 'height +org-capture-frame-parameters) 15)
;; (alist-get 'name +org-capture-frame-parameters) "❖ Capture") ;; ATM hardcoded in other places, so changing breaks stuff
(setq +org-capture-fn
      (lambda ()
        (interactive)
        (set-window-parameter nil 'mode-line-format 'none)
        (org-capture)))

(require 'org-download)
(add-hook 'org-mode-hook 'org-download-enable)
;; Use org-download-method directory is being used by default
(setq-default org-download-image-dir "~/kDrive/BC/Emacs/org/files/images")
(setq org-download-screenshot-method "gnome-screenshot -a -f %s")
(map! :leader
     (:prefix ("D" . "org-Downloader")
     :desc "Org-Download-Clipboard"
     "c" #'org-download-clipboard
     :leader
     :desc "Org-Download-Yank"
     "y" #'org-download-yank))

(use-package! org-sidebar
  :commands org-sidebar)
(map! :map org-mode-map
      :after org
      :localleader
      :desc "Sidebar" "S" #'org-sidebar-tree-toggle)

;; Let's make buffer creating a little easier
(evil-define-command evil-buffer-org-new (count file)
  "Creates a new ORG buffer replacing the current window, optionally
   editing a certain FILE"
  :repeat nil
  (interactive "P<f>")
  (if file
      (evil-edit file)
    (let ((buffer (generate-new-buffer "*new org*")))
      (set-window-buffer nil buffer)
      (with-current-buffer buffer
        (org-mode)))))
(map! :leader
      (:prefix "b"
       :desc "New empty ORG buffer" "o" #'evil-buffer-org-new))

;; Should - mostly do the trick
(defun org-syntax-convert-keyword-case-to-lower ()
  "Convert all #+KEYWORDS to #+keywords."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (let ((count 0)
          (case-fold-search nil))
      (while (re-search-forward "^[ \t]*#\\+[A-Z_]+" nil t)
        (unless (s-matches-p "RESULTS" (match-string 0))
          (replace-match (downcase (match-string 0)) t)
          (setq count (1+ count))))
      (message "Replaced %d occurances" count))))

(map! :leader
      :desc "Winner redo"
      "w <right>" #'winner-redo
      :leader
      :desc "Winner undo"
      "w <left>" #'winner-undo)

;; Preliminaries as seen in @jethro config.el
(use-package! org-roam
  :init
  (map! :leader
        :prefix "n"
        :desc "Org-roam" "l" #'org-roam-buffer-toggle
        :desc "Org-roam-graph" "g" #'org-roam-graph
        :desc "Org-roam-node-insert" "i" #'org-roam-node-insert
        :desc "Org-roam-dailies-goto-date" "d" #'org-roam-dailies-goto-date
        :desc "Org-roam-ref-find" "r" #'org-roam-ref-find
        :desc "Org-roam-dailies-goto-today" "t" #'org-roam-dailies-goto-today
        :desc "Org-roam-dailies-goto-yesterday" "y" #'org-roam-dailies-goto-yesterday
        :desc "Org-roam-node-random" "R" #'org-roam-node-random
        :desc "Org-roam-dailies-capture-today" "j" #'org-roam-dailies-capture-today
        :desc "Org-roam-dailies-goto-tomorrow" "T" #'org-roam-dailies-goto-tomorrow
        :desc "Org-roam-node-find" "f" #'org-roam-node-find
        :desc "Org-roam-capture" "c" #'org-roam-capture)
  (setq org-roam-directory "~/kDrive/BC/Emacs/org"
        org-roam-dailies-directory "~/kDrive/BC/Emacs/org/daily/"
        org-roam-db-gc-threshold gc-cons-threshold
        org-roam-v2-ack t
        org-id-link-to-org-use-id t
        org-roam-completion-everywhere t
;;        org-roam-node-display-template "${title:*} ${tags:40}"
        )
  :config
;;  (org-roam-db-autosync-enable)
  (define-key org-roam-mode-map [mouse-1] #'org-roam-visit-thing)
  (add-to-list 'display-buffer-alist
               '(("\\*org\\*"
                  (display-buffer-in-direction)
                  (direction . right)
                  (window-width . 0.33)
                  (window-height . fit-window-to-buffer))))
(setq org-roam-mode-section-functions
       (list #'org-roam-backlinks-section
             #'org-roam-reflinks-section
;;             #'org-roam-unlinked-references-section
           ))
(setq org-roam-capture-templates
        '(("d" "default" plain
           "%?"
           :if-new (file+head "${slug}.org"
                              "#+title: ${title}\n#+created: %<%Y-%m-%d>\n#+roam_tags:\n#+roam_aliases:\n#+roam_refs:\n#+filetags:\n")
           :immediate-finish t
           :unnarrowed t)))
      (setq org-roam-dailies-capture-templates
        '(("d" "default" entry
           "* %?"
           :if-new (file+head "%<%Y-%m-%d>.org"
                              "#+title: %<%A, %e %B %Y>\n#+roam_tags:\n#+roam_aliases:\n#+roam_refs:\n#+filetags:\n")))
        ))

(use-package! websocket
  :after org-roam)

(use-package! org-roam-ui
  :after org-roam
  :commands org-roam-ui-open
  :hook (org-roam . org-roam-ui-mode)
  :config
  (require 'org-roam) ; in case autoloaded
  (defun org-roam-ui-open ()
    "Ensure the server is active, then open the roam graph."
    (interactive)
    (unless org-roam-ui-mode (org-roam-ui-mode 1))
    (browse-url-xdg-open (format "http://localhost:%d" org-roam-ui-port))))

(after! org-agenda
  (org-super-agenda-mode))

(setq org-agenda-skip-scheduled-if-done t
      org-agenda-skip-deadline-if-done t
      org-agenda-include-deadlines t
      org-agenda-block-separator nil
      org-agenda-tags-column 100 ;; from testing this seems to be a good value
      org-agenda-compact-blocks t)

(setq org-agenda-custom-commands
      '(("o" "Overview"
         ((agenda "" ((org-agenda-span 'day)
                      (org-super-agenda-groups
                       '((:name "Today"
                          :time-grid t
                          :date today
                          :todo "TODAY"
                          :scheduled today
                          :order 1)))))
          (alltodo "" ((org-agenda-overriding-header "")
                       (org-super-agenda-groups
                        '((:name "Next to do"
                           :todo "NEXT"
                           :order 1)
                          (:name "Important"
                           :tag "Important"
                           :priority "A"
                           :order 6)
                          (:name "Due Today"
                           :deadline today
                           :order 2)
                          (:name "Due Soon"
                           :deadline future
                           :order 8)
                          (:name "Overdue"
                           :deadline past
                           :face error
                           :order 7)
                          (:name "Assignments"
                           :tag "Assignment"
                           :order 10)
                          (:name "Issues"
                           :tag "Issue"
                           :order 12)
                          (:name "Emacs"
                           :tag "Emacs"
                           :order 13)
                          (:name "Projects"
                           :tag "Project"
                           :order 14)
                          (:name "Research"
                           :tag "Research"
                           :order 15)
                          (:name "To read"
                           :tag "Read"
                           :order 30)
                          (:name "Waiting"
                           :todo "WAIT"
                           :order 20)
                          (:discard (:tag ("Chore" "Routine" "Daily")))))))))))

(use-package! org-journal
      :config
      (setq org-journal-dir "~/kDrive/BC/Emacs/org/"
      org-journal-date-prefix "#+TITLE: "
      org-journal-file-format "%Y-%m-%d.org"
      org-journal-date-format "%A, %d %B %Y"
    org-journal-enable-agenda-integration t))

;;(use-package! languagetool
  (map! :leader
        (:prefix ("l" . "languagecheck")
        :desc "Check with transient" "c" #'languagetool-check
        :leader
        :desc "Clear Buffer" "b" #'languagetool-clear-buffer
        :leader
        :desc "Check at point" "p" #'languagetool-correct-at-point
        :leader
        :desc "Correct buffer" "C" #'languagetool-correct-buffer
        :leader
        :desc "Set language" "s" #'languagetool-set-language))
  :config
  (setq languagetool-language-tool-jar "/home/jburkhard/.languagetool/languagetool-commandline.jar"
    ;; languagetool-server-language-tool-jar "/usr/share/java/languagetool/languagetool-server.jar"
        languagetool-java-arguments '("-Dfile.encoding=UTF-8")
        languagetool-default-language "en-US"
        languagetool-java-bin "/usr/bin/java")

(setq deft-directory "~/kDrive/BC/Emacs/org/"
deft-strip-summary-regexp ":PROPERTIES:\n\\(.+\n\\)+:END:\n"
deft-use-filename-as-title 't
deft-default-external "org")
(map! :leader
      :prefix "n"
      :desc "Open deft"
      "D" #'deft)

(map! :leader
      :desc "ERC"
      "o i" #'erc-tls)
(setq erc-server "irc.libera.chat"
      erc-nick "HeroP"
      erc-user-full-name "Jochen"
      erc-track-shorten-start 8
      erc-autojoin-chennels-alist '(("irc-libera-chat" "#systemcrafters" "#emacs"))
      erc-kill-buffer-on-part t
      erc-aut-query 'bury)

(use-package! calibredb
  :commands calibredb
  :config
  (setq calibredb-root-dir "~/kDrive/BC/Media/Calibre"
        calibredb-db-dir (expand-file-name "metadata.db" calibredb-root-dir))
  (map! :map calibredb-show-mode-map
        :ne "?" #'calibredb-entry-dispatch
        :ne "o" #'calibredb-find-file
        :ne "O" #'calibredb-find-file-other-frame
        :ne "V" #'calibredb-open-file-with-default-tool
        :ne "s" #'calibredb-set-metadata-dispatch
        :ne "e" #'calibredb-export-dispatch
        :ne "q" #'calibredb-entry-quit
        :ne "." #'calibredb-open-dired
        :ne [tab] #'calibredb-toggle-view-at-point
        :ne "M-t" #'calibredb-set-metadata--tags
        :ne "M-a" #'calibredb-set-metadata--author_sort
        :ne "M-A" #'calibredb-set-metadata--authors
        :ne "M-T" #'calibredb-set-metadata--title
        :ne "M-c" #'calibredb-set-metadata--comments)
  (map! :map calibredb-search-mode-map
        :ne [mouse-3] #'calibredb-search-mouse
        :ne "RET" #'calibredb-find-file
        :ne "?" #'calibredb-dispatch
        :ne "a" #'calibredb-add
        :ne "A" #'calibredb-add-dir
        :ne "c" #'calibredb-clone
        :ne "d" #'calibredb-remove
        :ne "D" #'calibredb-remove-marked-items
        :ne "j" #'calibredb-next-entry
        :ne "k" #'calibredb-previous-entry
        :ne "l" #'calibredb-virtual-library-list
        :ne "L" #'calibredb-library-list
        :ne "n" #'calibredb-virtual-library-next
        :ne "N" #'calibredb-library-next
        :ne "p" #'calibredb-virtual-library-previous
        :ne "P" #'calibredb-library-previous
        :ne "s" #'calibredb-set-metadata-dispatch
        :ne "S" #'calibredb-switch-library
        :ne "o" #'calibredb-find-file
        :ne "O" #'calibredb-find-file-other-frame
        :ne "v" #'calibredb-view
        :ne "V" #'calibredb-open-file-with-default-tool
        :ne "." #'calibredb-open-dired
        :ne "b" #'calibredb-catalog-bib-dispatch
        :ne "e" #'calibredb-export-dispatch
        :ne "r" #'calibredb-search-refresh-and-clear-filter
        :ne "R" #'calibredb-search-clear-filter
        :ne "q" #'calibredb-search-quit
        :ne "m" #'calibredb-mark-and-forward
        :ne "f" #'calibredb-toggle-favorite-at-point
        :ne "x" #'calibredb-toggle-archive-at-point
        :ne "h" #'calibredb-toggle-highlight-at-point
        :ne "u" #'calibredb-unmark-and-forward
        :ne "i" #'calibredb-edit-annotation
        :ne "DEL" #'calibredb-unmark-and-backward
        :ne [backtab] #'calibredb-toggle-view
        :ne [tab] #'calibredb-toggle-view-at-point
        :ne "M-n" #'calibredb-show-next-entry
        :ne "M-p" #'calibredb-show-previous-entry
        :ne "/" #'calibredb-search-live-filter
        :ne "M-t" #'calibredb-set-metadata--tags
        :ne "M-a" #'calibredb-set-metadata--author_sort
        :ne "M-A" #'calibredb-set-metadata--authors
        :ne "M-T" #'calibredb-set-metadata--title
        :ne "M-c" #'calibredb-set-metadata--comments))
;; Now, let's actually read the books
(use-package! nov
  :mode ("\\.epub\\'" . nov-mode)
  :config
  (map! :map nov-mode-map
        :n "RET" #'nov-scroll-up)

  (defun doom-modeline-segment--nov-info ()
    (concat
     " "
     (propertize
      (cdr (assoc 'creator nov-metadata))
      'face 'doom-modeline-project-parent-dir)
     " "
     (cdr (assoc 'title nov-metadata))
     " "
     (propertize
      (format "%d/%d"
              (1+ nov-documents-index)
              (length nov-documents))
      'face 'doom-modeline-info)))

  (advice-add 'nov-render-title :override #'ignore)

  (defun +nov-mode-setup ()
    (face-remap-add-relative 'variable-pitch
                             :family "Merriweather"
                             :height 1.4
                             :width 'semi-expanded)
    (face-remap-add-relative 'default :height 1.3)
    (setq-local line-spacing 0.2
                next-screen-context-lines 4
                shr-use-colors nil)
    (require 'visual-fill-column nil t)
    (setq-local visual-fill-column-center-text t
                visual-fill-column-width 80
                nov-text-width 80)
    (visual-fill-column-mode 1)
    (hl-line-mode -1)

    (add-to-list '+lookup-definition-functions #'+lookup/dictionary-definition)

    (setq-local mode-line-format
                `((:eval
                   (doom-modeline-segment--workspace-name))
                  (:eval
                   (doom-modeline-segment--window-number))
                  (:eval
                   (doom-modeline-segment--nov-info))
                  ,(propertize
                    " %P "
                    'face 'doom-modeline-buffer-minor-mode)
                  ,(propertize
                    " "
                    'face (if (doom-modeline--active) 'mode-line 'mode-line-inactive)
                    'display `((space
                                :align-to
                                (- (+ right right-fringe right-margin)
                                   ,(* (let ((width (doom-modeline--font-width)))
                                         (or (and (= width 1) 1)
                                             (/ width (frame-char-width) 1.0)))
                                       (string-width
                                        (format-mode-line (cons "" '(:eval (doom-modeline-segment--major-mode))))))))))
                  (:eval (doom-modeline-segment--major-mode)))))

  (add-hook 'nov-mode-hook #'+nov-mode-setup))

(setq calc-angle-mode 'rad  ; radians are rad
      calc-symbolic-mode t) ; keeps expressions like \sqrt{2} irrational for as long as possible
