;;; lsp-mlua.el --- LSP Clients for mLua  -*- lexical-binding: t; -*-

;; Copyright (C) 2026  Shen, Jen-Chieh

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; Maintainer: Shen, Jen-Chieh <jcs090218@gmail.com>
;; URL: https://github.com/MSW-cmty/lsp-mlua
;; Version: 0.0.1
;; Package-Requires: ((emacs "29.1") (lsp-mode "6.1"))
;; Keywords: convenience lsp

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; LSP Clients for mLua.
;;

;;; Code:

(require 'lsp-mode)

(defgroup lsp-mlua nil
  "Settings for the mLua language server."
  :group 'lsp-mode
  :link '(url-link "https://github.com/MSW-cmty/lsp-mlua"))

(defcustom lsp-mlua-unzipped-path (f-join lsp-server-install-dir "mlua/unzipped")
  "The path to the file in which `mlua' will be stored."
  :type 'file
  :group 'lsp-mlua)

(defcustom lsp-mlua-download-url "https://github.com/MSW-cmty/lsp-server-binaries/blob/main/msw.mlua-1.1.5.vsix?raw=true"
  "The mLua language server download url."
  :type 'string
  :group 'lsp-mlua)

(defcustom lsp-mlua-server-command `("node"
                                     "~/scripts/server/out/languageServer.js"
                                     "--stdio")
  "Command to start mLua server."
  :risky t
  :type '(repeat string)
  :group 'lsp-mlua)

(defcustom lsp-mlua-node "node"
  "Path to Node.js."
  :type 'file
  :group 'lsp-mlua)

(defcustom lsp-mlua-multi-root nil
  "If non nil, `mlua' will be started in multi-root mode."
  :type 'boolean
  :safe #'booleanp
  :group 'lsp-mlua)

(defun lsp-mlua-server-exists? (cmd)
  "Return non-nil if the server CMD exists."
  (let* ((command-name (f-base (f-filename (cl-first cmd))))
         (first-argument (cl-second cmd))
         (first-argument-exist (and first-argument (file-exists-p first-argument))))
    (if (equal command-name lsp-mlua-node)
        first-argument-exist
      (executable-find (cl-first cmd)))))

(defun lsp-mlua-server-command ()
  "Return the mLua server command."
  (if (lsp-mlua-server-exists? lsp-mlua-server-command)
      lsp-mlua-server-command
    `(,lsp-mlua-node ,(f-join lsp-mlua-unzipped-path
                              "extension/scripts/server/out/languageServer.js")
                     "--stdio")))

(lsp-register-client
 (make-lsp-client
  :new-connection
  (lsp-stdio-connection
   (lambda () (lsp-mlua-server-command))
   (lambda () (lsp-mlua-server-exists? (lsp-mlua-server-command))))
  :langua-id
  :initialization-options
  (lambda ()
    `((capabilities . (completionCapability
                       . ((codeBlockScriptSnippetCompletion . t)
                          (codeBlockBTNodeSnippetCompletion . t)
                          (commitCharacterSupport           . t))
                       ))
      (profileMode . :json-false)
      (stopwatch   . :json-false)))
  :activation-fn (lambda (filename &optional _)
                   (string-match-p "\\.mlua\\'" filename))
  :priority -1
  :completion-in-comments? t
  :add-on? t
  :multi-root lsp-mlua-multi-root
  :server-id 'msw.mlua
  :download-server-fn (lambda (_client callback error-callback _update?)
                        (let ((tmp-zip (make-temp-file "ext" nil ".zip")))
                          (delete-file tmp-zip)
                          (lsp-download-install
                           (lambda (&rest _)
                             (condition-case err
                                 (progn
                                   (lsp-unzip tmp-zip lsp-mlua-unzipped-path)
                                   (funcall callback))
                               (error (funcall error-callback err))))
                           error-callback
                           :url lsp-mlua-download-url
                           :store-path tmp-zip)))))

(provide 'lsp-mlua)
;;; lsp-mlua.el ends here
