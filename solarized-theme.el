(require 'lunarized-definitions
         (locate-file "lunarized-definitions.el" custom-theme-load-path
                      '("c" "")))

(create-lunarized-theme lunarized
                        lunarized-description (lunarized-color-definitions))
