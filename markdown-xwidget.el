;;; markdown-xwidget.el --- Markdown preview with xwidgets  -*- lexical-binding: t; -*-

;; Author: Chris Clark <cfclrk@gmail.com>
;; Version: 0.1
;; Package-Requires: ((emacs "26.1") (markdown-mode "2.5") (f "0.20.0") (ht "2.4") (mustache "0.24"))
;; Keywords: convenience tools
;; URL: https://github.com/cfclrk/markdown-xwidget

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; See documentation at https://github.com/cfclrk/markdown-xwidget

;;; Code:

(require 'xwidget)
(require 'markdown-mode)
(require 'mustache)
(require 'ht)
(require 'f)

;;;; variables

(defconst markdown-xwidget-directory
  (file-name-directory (if load-in-progress
                           load-file-name
                         (buffer-file-name)))
  "The package directory of markdown-xwidget.")

(defgroup markdown-xwidget nil
  "Markdown preview using xwidgets."
  :group 'markdown-xwidget)

(defcustom markdown-xwidget-github-theme
  "light"
  "The GitHub CSS theme to use for rendering markdown documents."
  :type '(choice
          (string "light")
          (string "light-colorblind")
          (string "light-high-contrast")
          (string "light-tritanopia")
          (string "dark")
          (string "dark-dimmed")
          (string "dark-colorblind")
          (string "dark-high-contrast")
          (string "dark-tritanopia"))
  :group 'markdown-xwidget)

(defcustom markdown-xwidget-code-block-theme
  "github"
  "The highlight.js CSS theme to use for syntax highlighting in code blocks.
The highlight.js themes are defined here:
https://github.com/highlightjs/highlight.js/tree/main/src/styles"
  :type 'string)

(defcustom markdown-xwidget-mermaid-theme
  "default"
  "The mermaid theme to use for rendering mermaid diagrams.
Mermaid themes are enumerated here:
https://mermaid-js.github.io/mermaid/#/theming?id=deployable-themes"
  :type '(choice
          (string "base")
          (string "forest")
          (string "dark")
          (string "default")
          (string "neutral"))
  :group 'markdown-xwidget)

;;;; functions

(defun markdown-xwidget-preview (file)
  "Preview FILE with xwidget-webkit.
To be used with `markdown-live-preview-window-function'."
  (let ((uri (format "file://%s" file)))
    (xwidget-webkit-browse-url uri)
    xwidget-webkit-last-session-buffer))

(defun markdown-xwidget-resource (rel-path)
  "Return the absolute path for REL-PATH.
REL-PATH is a path relative to the resources/ directory in this
project."
  (expand-file-name (f-join "resources/" rel-path) markdown-xwidget-directory))

(defun markdown-xwidget-github-css-path (theme-name)
  "Return the absolute path to the github THEME-NAME file."
  (markdown-xwidget-resource (concat "github_css/" theme-name ".css")))

(defun markdown-xwidget-highlightjs-css-path (theme-name)
  "Return the absolute path to the highlight.js THEME-NAME file."
  (markdown-xwidget-resource (concat "highlight_css/" theme-name ".min.css")))

;;;; markdown-mode configuration

(setq markdown-command "multimarkdown")

(if (featurep 'xwidget-internal)
    (setq markdown-live-preview-window-function #'markdown-xwidget-preview)
  (message "You cannot use markdown-xwidget because your Emacs does not
support xwidgets. See the markdown-xwidget README.md for info about how
to obtain Emacs with support for xwidgets."))

;;;; watchers

;; Whenever the `markdown-xwidget-github-theme' variable changes value (say,
;; through user customization), we need to update the `markdown-css-paths'
;; variable (which is defined in `markdown-mode').

(add-variable-watcher 'markdown-xwidget-github-theme
 (lambda (_ newval _ _)
   (let ((old-theme (markdown-xwidget-github-css-path
                     markdown-xwidget-github-theme))
         (new-theme (markdown-xwidget-github-css-path
                     newval)))
     ;; Delete the old theme
     (setq markdown-css-paths (delete old-theme markdown-css-paths))
     ;; Add the new theme
     (add-to-list 'markdown-css-paths new-theme))))

;; Whenever the `markdown-xwidget-code-block-theme' variable changes value (say,
;; through user customization), we need to update the `markdown-css-paths'
;; variable (which is defined in `markdown-mode').

(add-variable-watcher
 'markdown-xwidget-code-block-theme
 (lambda (_ newval _ _)
   (let ((old-theme (markdown-xwidget-highlightjs-css-path
                     markdown-xwidget-code-block-theme))
         (new-theme (markdown-xwidget-highlightjs-css-path
                     newval)))
     ;; Delete the old theme
     (setq markdown-css-paths (delete old-theme markdown-css-paths))
     ;; Add the new theme
     (add-to-list 'markdown-css-paths new-theme))))

;; Whenever the `markdown-xwidget-mermaid-theme' variable changes value (say,
;; through user customization), we need to update the
;; `markdown-xwidget-header-html' variable to include a link to the new mermaid
;; CSS file.

(add-variable-watcher
 'markdown-xwidget-mermaid-theme
 (lambda (_ newval _ _)
   (setq markdown-xhtml-header-content
         (markdown-xwidget-header-html newval))))

;;;; markdown-css-paths

;; Set the initial value for `markdown-css-paths'. Its contents will be updated
;; (via watchers) if you customize `markdown-xwidget-github-theme' or
;; `markdown-xwidget-code-block-theme'.

(let ((github-theme (markdown-xwidget-github-css-path
                     markdown-xwidget-github-theme))
      (code-block-theme (markdown-xwidget-highlightjs-css-path
                         markdown-xwidget-code-block-theme)))
  (setq markdown-css-paths (list github-theme code-block-theme)))

;;;; markdown-xwidgethtml-header-content

(defun markdown-xwidget-header-html (mermaid-theme)
  "Return header HTML with all js and MERMAID-THEME templated in.
Meant for use with `markdown-xwidgethtml-header-content'."
  (let ((context
         (ht ("highlight-js"  (markdown-xwidget-resource "highlight.min.js"))
             ("mermaid-js"    (markdown-xwidget-resource "mermaid.min.js"))
             ("mathjax-js"    (markdown-xwidget-resource "tex-mml-chtml.js"))
             ("mermaid-theme" mermaid-theme)))

        (html-template
         (f-read-text (markdown-xwidget-resource "header.html"))))

    ;; Render the HTML from a mustache template
    (mustache-render html-template context)))

;; Set the initial value of `markdown-xwidgethtml-header-content'. This will be
;; updated via a watcher if `markdown-xwidget-mermaid-theme' is customized.
(setq markdown-xhtml-header-content
      (markdown-xwidget-header-html markdown-xwidget-mermaid-theme))

(provide 'markdown-xwidget)
;;; markdown-xwidget.el ends here