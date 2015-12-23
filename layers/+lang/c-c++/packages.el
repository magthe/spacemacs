;;; packages.el --- C/C++ Layer packages File for Spacemacs
;;
;; Copyright (c) 2012-2014 Sylvain Benner
;; Copyright (c) 2014-2015 Sylvain Benner & Contributors
;;
;; Author: Sylvain Benner <sylvain.benner@gmail.com>
;; URL: https://github.com/syl20bnr/spacemacs
;;
;; This file is not part of GNU Emacs.
;;
;;; License: GPLv3

(setq c-c++-packages
  '(
    cc-mode
    disaster
    clang-format
    cmake-mode
    company
    company-c-headers
    company-ycmd
    flycheck
    gdb-mi
    helm-cscope
    helm-gtags
    semantic
    stickyfunc-enhance
    rtags
    ycmd
    xcscope
    ))

(unless (version< emacs-version "24.4")
  (add-to-list 'c-c++-packages 'srefactor))

(defun c-c++/init-cc-mode ()
  (use-package cc-mode
    :defer t
    :init
    (add-to-list 'auto-mode-alist `("\\.h$" . ,c-c++-default-mode-for-headers))
    :config
    (progn
      (require 'compile)
      (c-toggle-auto-newline 1)
      (spacemacs/set-leader-keys-for-major-mode 'c-mode
        "ga" 'projectile-find-other-file
        "gA" 'projectile-find-other-file-other-window)
      (spacemacs/set-leader-keys-for-major-mode 'c++-mode
        "ga" 'projectile-find-other-file
        "gA" 'projectile-find-other-file-other-window))))

(defun c-c++/init-disaster ()
  (use-package disaster
    :defer t
    :commands (disaster)
    :init
    (progn
      (spacemacs/set-leader-keys-for-major-mode 'c-mode
        "D" 'disaster)
      (spacemacs/set-leader-keys-for-major-mode 'c++-mode
        "D" 'disaster))))

(defun c-c++/init-clang-format ()
  (use-package clang-format
    :if c-c++-enable-clang-support))

(defun c-c++/init-cmake-mode ()
  (use-package cmake-mode
    :mode (("CMakeLists\\.txt\\'" . cmake-mode) ("\\.cmake\\'" . cmake-mode))
    :init (push 'company-cmake company-backends-cmake-mode)))

(defun c-c++/post-init-company ()
    (spacemacs|add-company-hook c-mode-common)
    (spacemacs|add-company-hook cmake-mode)

    (when c-c++-enable-clang-support
      (push 'company-clang company-backends-c-mode-common)

      (defun company-mode/more-than-prefix-guesser ()
        (c-c++/load-clang-args)
        (company-clang-guess-prefix))

      (setq company-clang-prefix-guesser 'company-mode/more-than-prefix-guesser)))

(when (configuration-layer/layer-usedp 'auto-completion)
  (defun c-c++/init-company-c-headers ()
    (use-package company-c-headers
      :if (configuration-layer/package-usedp 'company)
      :defer t
      :init (push 'company-c-headers company-backends-c-mode-common))))

(defun c-c++/post-init-flycheck ()
  (dolist (hook '(c-mode-hook c++-mode-hook))
    (spacemacs/add-flycheck-hook hook))
  (when c-c++-enable-clang-support
    (spacemacs/add-to-hooks 'c-c++/load-clang-args '(c-mode-hook c++-mode-hook))))

(defun c-c++/init-gdb-mi ()
  (use-package gdb-mi
    :defer t
    :init
    (setq
     ;; use gdb-many-windows by default when `M-x gdb'
     gdb-many-windows t
     ;; Non-nil means display source file containing the main routine at startup
     gdb-show-main t)))

(defun c-c++/post-init-helm-gtags ()
  (spacemacs/helm-gtags-define-keys-for-mode 'c-mode)
  (spacemacs/helm-gtags-define-keys-for-mode 'c++-mode))

(defun c-c++/post-init-semantic ()
  (semantic/enable-semantic-mode 'c-mode)
  (semantic/enable-semantic-mode 'c++-mode))

(defun c-c++/post-init-srefactor ()
  (spacemacs/set-leader-keys-for-major-mode 'c-mode "r" 'srefactor-refactor-at-point)
  (spacemacs/set-leader-keys-for-major-mode 'c++-mode "r" 'srefactor-refactor-at-point)
  (spacemacs/add-to-hooks 'spacemacs/lazy-load-srefactor '(c-mode-hook c++-mode-hook)))

(defun c-c++/post-init-stickyfunc-enhance ()
  (spacemacs/add-to-hooks 'spacemacs/lazy-load-stickyfunc-enhance '(c-mode-hook c++-mode-hook)))

(defun c-c++/post-init-ycmd ()
  (add-hook 'c++-mode-hook 'ycmd-mode)
  (spacemacs/set-leader-keys-for-major-mode 'c++-mode
    "gg" 'ycmd-goto
    "gG" 'ycmd-goto-imprecise))

(defun c-c++/post-init-company-ycmd ()
  (push 'company-ycmd company-backends-c-mode-common))

(defun c-c++/pre-init-xcscope ()
  (spacemacs|use-package-add-hook xcscope
    :post-init
    (dolist (mode '(c-mode c++-mode))
      (spacemacs/set-leader-keys-for-major-mode mode "gi" 'cscope-index-files))))

(defun c-c++/pre-init-helm-cscope ()
  (spacemacs|use-package-add-hook xcscope
    :post-init
    (dolist (mode '(c-mode c++-mode))
      (spacemacs/setup-helm-cscope mode))))

(defun c-c++/init-rtags ()
  (use-package rtags
    :defer t
    :if c-c++-enable-rtags-support
    :init
    (progn
      (push 'company-rtags company-backends-c-mode-common)
      (setq rtags-completions-enabled t
            company-rtags-begin-after-member-access nil))))

(defun c-c++/post-init-rtags ()
  (when c-c++-enable-rtags-support
    (defun use-rtags (&optional useFileManager)
      (and (rtags-executable-find "rc")
           (cond ((not (gtags-get-rootpath)) t)
                 ((and (not (eq major-mode 'c++-mode))
                       (not (eq major-mode 'c-mode))) (rtags-has-filemanager))
                 (useFileManager (rtags-has-filemanager))
                 (t (rtags-is-indexed)))))

    (defun tags-find-symbol-at-point (&optional prefix)
      (interactive "P")
      (if (and (not (rtags-find-symbol-at-point prefix)) rtags-last-request-not-indexed)
          (helm-gtags-find-tag)))

    (defun tags-find-references-at-point (&optional prefix)
      (interactive "P")
      (if (and (not (rtags-find-references-at-point prefix)) rtags-last-request-not-indexed)
          (helm-gtags-find-rtag)))

    (defun tags-find-symbol ()
      (interactive)
      (call-interactively (if (use-rtags) 'rtags-find-symbol 'helm-gtags-find-symbol)))

    (defun tags-find-references ()
      (interactive)
      (call-interactively (if (use-rtags) 'rtags-find-references 'helm-gtags-find-rtag)))

    (defun tags-find-file ()
      (interactive)
      (call-interactively (if (use-rtags t) 'rtags-find-file 'helm-gtags-find-files)))

    (defun tags-imenu ()
      (interactive)
      (call-interactively (if (use-rtags t) 'rtags-imenu 'idomenu)))

    (dolist (mode '(c-mode c++-mode))
      (evil-leader/set-key-for-mode mode
        "r ." 'rtags-find-symbol-at-point
        "r ," 'rtags-find-references-at-point
        "r v" 'rtags-find-virtuals-at-point
        "r V" 'rtags-print-enum-value-at-point
        "r /" 'rtags-find-all-references-at-point
        "r Y" 'rtags-cycle-overlays-on-screen
        "r >" 'rtags-find-symbol
        "r <" 'rtags-find-references
        "r [" 'rtags-location-stack-back
        "r ]" 'rtags-location-stack-forward
        "r D" 'rtags-diagnostics
        "r G" 'rtags-guess-function-at-point
        "r p" 'rtags-set-current-project
        "r P" 'rtags-print-dependencies
        "r e" 'rtags-reparse-file
        "r E" 'rtags-preprocess-file
        "r R" 'rtags-rename-symbol
        "r M" 'rtags-symbol-info
        "r S" 'rtags-display-summary
        "r O" 'rtags-goto-offset
        "r ;" 'rtags-find-file
        "r F" 'rtags-fixit
        "r L" 'rtags-copy-and-print-current-location
        "r X" 'rtags-fix-fixit-at-point
        "r B" 'rtags-show-rtags-buffer
        "r I" 'rtags-imenu
        "r T" 'rtags-taglist
        "r h" 'rtags-print-class-hierarchy
        "r a" 'rtags-print-source-arguments))

    (rtags-enable-standard-keybindings)
    (define-key c-mode-base-map (kbd "M-.") (function tags-find-symbol-at-point))
    (define-key c-mode-base-map (kbd "M-,") (function tags-find-references-at-point))
    (define-key c-mode-base-map (kbd "M-;") (function tags-find-file))
    (define-key c-mode-base-map (kbd "C-.") (function tags-find-symbol))
    (define-key c-mode-base-map (kbd "C-,") (function tags-find-references))
    (define-key c-mode-base-map (kbd "C-<") (function rtags-find-virtuals-at-point))
    (define-key c-mode-base-map (kbd "M-i") (function tags-imenu))

    (define-key global-map (kbd "M-.") (function tags-find-symbol-at-point))
    (define-key global-map (kbd "M-,") (function tags-find-references-at-point))
    (define-key global-map (kbd "M-;") (function tags-find-file))
    (define-key global-map (kbd "C-.") (function tags-find-symbol))
    (define-key global-map (kbd "C-,") (function tags-find-references))
    (define-key global-map (kbd "C-<") (function rtags-find-virtuals-at-point))
    (define-key global-map (kbd "M-i") (function tags-imenu))))
