(require 'use-package-ensure)
(setq use-package-always-ensure t)

(setq user-emacs-directory
      (concat (getenv "XDG_CONFIG_HOME") "/emacs"))
(use-package no-littering
  :init
  (require 'no-littering))

(set-face-attribute 'default nil :height 130)

(setq create-lockfiles nil)
(global-auto-revert-mode)
(save-place-mode)

(setq cache-dir (concat (getenv "XDG_CACHE_HOME") "/emacs"))
(setq auto-save-list-file-prefix cache-dir
      auto-save-file-name-transforms `((".*" ,cache-dir t))
      backup-directory-alist `(("." . ,cache-dir)))
(setopt use-short-answers t)
(setq ring-bell-function 'ignore)
(set-face-attribute 'default nil :height 150)
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(setq scroll-step 1)
(pixel-scroll-precision-mode)
(recentf-mode)
(save-place-mode)
(setq-default tab-width 4)
(setq-default indent-tabs-mode nil)
(setq split-width-threshold 100) ;; prefer horizontal split
(setq display-buffer-reuse-frames t)

(use-package which-key
  :ensure nil
  :init
  (setq which-key-idle-delay 0.5)
  (which-key-mode))

(add-to-list 'default-frame-alist '(alpha-background . 92))
(defun my/toggle-opacity ()
  (interactive)
  (let* ((cur-frame (current-frame))
         (cur-val (frame-parameter cur-frame 'alpha-background)))
    (set-frame-parameter
     cur-frame 'alpha-background
     (if (= cur-val 100)
         (alist-get 'alpha-background default-frame-alist)
       100))))


(use-package ef-themes
  ;; :init
  ;; (load-theme 'ef-melissa-dark t)
  )

(use-package gruvbox-theme
  :init
  (load-theme 'gruvbox-dark-hard t)
  )

;; (use-package mixed-pitch
;;   :hook ((text-mode . mixed-pitch-mode))
;;   :init
;;   (defun my/set-fonts ()
;;       (let ((fixed "Hack")
;;             (variable "Iosevka")
;;             (font-size 128))
;;         (set-face-attribute 'default nil
;;                             :font fixed
;;                             :height font-size)
;;         (set-face-attribute 'fixed-pitch nil
;;                             :font fixed
;;                             :height font-size)
;;         (set-face-attribute 'variable-pitch
;;                             ;; :font variable
;;                             :font fixed
;;                             :height font-size)
;;         ))
;;   (if (daemonp)
;;       (add-hook 'after-make-frame-functions
;;                 (lambda (frame)
;;                   (with-selected-frame frame
;;                     (my/set-fonts))))
;;     (my/set-fonts))
;;   )

(use-package olivetti
  :init
  (setq olivetti-body-width 0.8)
  :hook
  (prog-mode . olivetti-mode)
  (text-mode . olivetti-mode)
  (dired-mode . olivetti-mode))

(use-package hide-mode-line
  :init
  (global-hide-mode-line-mode))


;; Vi emulation
(defun my/escape-if-next-char-is (c)
  "Watches the next letter. If c, revert to 'evil-normal-state. Inspired by https://gist.github.com/timcharper/822738"
  (let ((next-key (read-event)))
    (if (= c next-key)
        (evil-normal-state)
      (progn
        (insert-char c)
        (insert-char next-key)))))

(defun my/escape-if-next-char-is-j (arg)
  (interactive "p")
  (if (= arg 1)
      (my/escape-if-next-char-is ?j)
    (self-insert-command arg)))

(use-package evil
  :demand t
  :init
  (setq evil-want-integration t
		evil-want-minibuffer t
		evil-want-keybinding nil
        evil-want-C-i-jump t
		evil-search-module 'evil-search
		evil-ex-search-persistent-highlight nil
		evil-ex-complete-emacs-commands t
		evil-vsplit-window-right t
		evil-split-window-below t
		evil-shift-round nil
		evil-want-C-u-scroll t
		tab-always-indent 'complete)
  (electric-pair-mode)
  (evil-mode 1)

  :config
  (evil-set-undo-system 'undo-redo)

  (defun w ()
	"Save the current buffer"
	(interactive)
	(save-buffer)
	t)

  (defun q ()
	"Close the current buffer"
	(interactive)
	(evil-quit)
	t)

  (defun qa ()
	"Close all buffers"
	(interactive)
	(evil-quit-all)
	t)

  (defun wq ()
	"Save and close the current buffer"
	(interactive)
	(and (w) (q)))

  (defun vs ()
	"Open a vertical split"
	(interactive)
	(evil-window-vsplit))

  (defun sp ()
	"Open a horizontal split"
	(interactive)
	(evil-window-split))

  (defun my/launch-dired ()
	(interactive)
	(or (dired-jump) (dired-up-directory)))

  (defun my/where-am-i ()
	(interactive)
	(message buffer-file-name))

  (evil-define-operator my/comment-operator (beg end)
	"Comment out lines selected by motion"
	:restore-point t
	(comment-region beg end))

  :bind (("M-l" . evil-window-right)
		 ("M-h" . evil-window-left)
		 ("M-j" . evil-window-down)
		 ("M-k" . evil-window-up)
		 ("M-H v" . describe-variable)
		 ("M-H f" . describe-function)
		 ("M-H k" . describe-key)

		 :map evil-motion-state-map
		 ("gc" . my/comment-operator)

		 :map evil-normal-state-map
		 ("-" . my/launch-dired)
		 (";" . execute-extended-command)
		 ("SPC q" . kill-current-buffer)
		 ("SPC r" . recompile)
		 ("SPC SPC g" . magit)
		 ("SPC f f" . find-file)
		 ("SPC f h" . consult-recent-file)
		 ("SPC fb" . consult-buffer)
		 ("SPC fw" . consult-ripgrep)
		 ("SPC fl" . consult-line)

		 ("SPC tn" . display-line-numbers-mode)
		 ("SPC wtf" . my/where-am-i)
		 ("C-M-f" . eval-last-sexp)
		 ("C-f" . eval-defun)
		 ("C-/" . comment-line)
		 ("C-_" . comment-line)

		 ("C-k" . evil-scroll-up)
		 ("C-j" . evil-scroll-down)

		 :map evil-insert-state-map
		 ("j" . my/escape-if-next-char-is-j)
		 ("M-h" . backward-delete-char-untabify)
		 ("C-k" . nil))

  :hook ((evil-jumps-post-jump . my/where-am-i)
		 (xref-after-jump . my/where-am-i)))

(use-package evil-collection
  :init
  (evil-collection-init))
(use-package evil-surround
  :config
  (global-evil-surround-mode 1))

(use-package avy
  :init
  (setq avy-timeout-seconds 0.3)
  :bind (:map evil-normal-state-map
			  ("s" . avy-goto-char-timer)
			  :map evil-motion-state-map
			  ("s" . avy-goto-char-timer)))


;; Command buffer
(use-package vertico
  :init
  (setq vertico-count 15)
  (vertico-mode)

  (defun my/pos-at-beginning-of-line-text ()
	(save-excursion
	  (beginning-of-line-text)
	  (point)))

  (defun my/find-char-backward (ch)
	(letrec
		((bol (my/pos-at-beginning-of-line-text))
		 (find-ch (lambda ()
					(let ((cur (point)))
					  (cond
					   ((= ch (char-before)) cur)
					   ((= cur bol)
						(error "%c not found in current line" ch))
					   (t (backward-char 1)
						  (funcall find-ch)))))))
	  (save-excursion
		(funcall find-ch))))

  (defun my/delete-word-backward ()
	(interactive)
	(let ((delete-to-previous-slash
		   (lambda ()
			 (when (= (char-before) ?/)
			   (backward-delete-char 1))
			 (delete-region (my/find-char-backward ?/)
							(point)))))
	  (condition-case _
		  (funcall delete-to-previous-slash)
		(error (backward-kill-word 1)))))

  :bind (:map vertico-map
		 ("C-c" . abort-minibuffers)
		 ("M-h" . backward-delete-char-untabify)
		 :map evil-ex-map
		 ("C-c" . abort-minibuffers)
		 :map minibuffer-mode-map
		 ("C-c" . abort-minibuffers)
		 ("C-h" . my/delete-word-backward)
		 ("C-j" . vertico-next)
		 ("C-k" . vertico-previous)))

(use-package marginalia
  :bind (:map minibuffer-local-map
			  ("M-A" . marginalia-cycle))
  :init
  (marginalia-mode))

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles basic partial-completion)))))

(use-package savehist
  :ensure nil
  :init
  (savehist-mode))

(use-package consult
  :demand t
  :config
  (setq completion-in-region-function #'consult-completion-in-region
		xref-show-xrefs-function #'consult-xref
		xref-show-definitions-function #'consult-xref))


(use-package project
  :ensure nil
  :bind (:map evil-normal-state-map
			  ("SPC p s" . project-switch-project)
			  ("SPC p f" . project-find-file)
			  ("SPC p w" . consult-git-grep))
  :init
  (let ((open-magit-in-project-root
		 (lambda () (interactive)
		   (magit (car (last (project-current))))))
		(open-consult-ripgrep-in-project-root
		 (lambda () (interactive)
		   (consult-ripgrep (car (last (project-current)))))))
	(setq project-switch-commands
		  (list
		   (list open-magit-in-project-root "Magit" "g")
		   (list #'project-find-file "Find file" "f")
		   (list open-consult-ripgrep-in-project-root "Find word" "w")
		   (list #'project-eshell "Eshell" "e")))))


(use-package magit
  :bind (:map evil-normal-state-map
			  ("SPC SPC g" . magit)))
(use-package git-gutter
  :hook (prog-mode . git-gutter-mode)
  :config
  (setq git-gutter:update-interval 0.02)
  :bind (:map evil-normal-state-map
			  ("SPC g n" . git-gutter:next-hunk)
			  ("SPC g p" . git-gutter:previous-hunk)
			  ("SPC g s" . git-gutter:stage-hunk)
			  ("SPC g P" . git-gutter:popup-hunk)
			  ("SPC g r" . git-gutter:revert-hunk)))
(use-package git-gutter-fringe
  :config
  (setq-default fringes-outside-margins t)
  (fringe-mode 4)

  (define-fringe-bitmap 'git-gutter-fr:added [#b11100000] nil nil '(center repeated))
  (define-fringe-bitmap 'git-gutter-fr:modified [#b11100000] nil nil '(center repeated))
  (define-fringe-bitmap 'git-gutter-fr:deleted
	[#b10000000
	 #b11000000
	 #b11100000
	 #b11110000]
	nil nil 'bottom))



;; Dired
(use-package dired
  :ensure nil
  :init
  (setq dired-auto-revert-buffer t
		dired-kill-when-opening-new-dired-buffer t))


(use-package paren-face
  :init
  (global-paren-face-mode))


(use-package eglot
  :bind (:map evil-normal-state-map
			  ("SPC SPC e" . eglot)
			  ("C-c C-d" . eldoc)
			  ("SPC ed" . eldoc)
			  ("C-c C-e" . eglot-rename)
			  ("SPC er" . eglot-rename)
			  ("C-c C-f" . eglot-format)
			  ("SPC ef" . eglot-format)
			  ("SPC en" . flymake-goto-next-error)
			  ("SPC ep" . flymake-goto-prev-error))

  :hook ((nix-ts-mode . eglot-ensure))
  :config
  (add-hook 'eglot-managed-mode-hook
			#'flymake-mode)

  (setq eglot-workspace-configuration
		'(
		  ;; https://kokada.dev/blog/make-nixd-module-completion-to-work-anywhere-with-flakes/
		  (:nixd (:nixpkgs
				  (:expr "import \"${flake.inputs.nixpkgs}\" { }"))
				 (:formatting
				  (:command '("nix" "fmt")))
				 (:options
				  ((:nixos (:expr "(let pkgs = import \"${inputs.nixpkgs}\" { }; in (pkgs.lib.evalModules { modules =  (import \"${inputs.nixpkgs}/nixos/modules/module-list.nix\") ++ [ ({...}: { nixpkgs.hostPlatform = builtins.currentSystem;} ) ] ; })).options"))
				   (:home-manager (:expr "(let pkgs = import \"${inputs.nixpkgs}\" { }; lib = import \"${inputs.home-manager}/modules/lib/stdlib-extended.nix\" pkgs.lib; in (lib.evalModules { modules =  (import \"${inputs.home-manager}/modules/modules.nix\") { inherit lib pkgs; check = false; }; })).options"))))))))


(use-package nix-ts-mode
  :mode "\\.nix\\'")


(use-package copilot
  :bind (:map global-map
              ("M-:" . nil)
              :map evil-normal-state-map
              ("M-:" . eval-expression)
              :map evil-insert-state-map
              ("M-;" . copilot-accept-completion)
              ("M-:" . copilot-accept-completion-by-word)
              ("C-M-;" . copilot-next-completion))

  :hook ((text-mode . copilot-mode)
         (prog-mode . copilot-mode))

  :config
  (add-to-list 'copilot-indentation-alist
               '(emacs-lisp-mode 2))
  (add-to-list 'copilot-indentation-alist
               '(text-mode 0))
  (add-to-list 'copilot-indentation-alist
               '(minibuffer-mode 0))
  (add-to-list 'copilot-indentation-alist
               '(nix-ts-mode 2))
  )
