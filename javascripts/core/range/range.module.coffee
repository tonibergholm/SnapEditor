define ["cs!core/browser", "cs!core/range/range.w3c", "cs!core/range/range.ie"], (Browser, W3C, IE) ->
  # Add browser specific functions.
  # TODO: Figure out how to require either W3C or IE. This solution doesn't
  # work because #require() is asynchronous. Range is returns before the
  # require block has a chance to extend/include the module. The current
  # solution is to require both in the define array and only use one of the
  # modules.
  #module = "range.#{if Browser.isIE then "ie" else "w3c"}"
  #require ["cs!core/#{module}"], (Module) ->
    #Helpers.extend(Range, Module.static)
    #Helpers.include(Range, Module.instance)

  Module = if Browser.hasW3CRanges then W3C else IE
  return Module
