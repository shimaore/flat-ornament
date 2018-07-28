Pattern
-------

Does the number `n` match the pattern `p`.

The pattern must consists of only:
- digits
- '?', '.' -- replace single of above
- '..', '...', '…' -- replace zero or more

    module.exports = pattern = (p) ->

      p = p
        .replace /\.\.|\.\.\.|…/g, '\\d*'
        .replace /\?|\./g, '\\d'

      new RegExp "^#{p}$"
