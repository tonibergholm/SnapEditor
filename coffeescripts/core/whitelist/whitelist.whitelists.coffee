# This generates the following whitelists given the whtielist:
# * defaults
# * byLabel
# * byTag
#
# The values are stored as Whitelist.Objects.
define ["jquery.custom", "core/whitelist/whitelist.object"], ($, WhitelistObject) ->
  class Whitelists
    constructor: (whitelist) ->
      @defaults = {} # { *: "label", tag: "label" }
      @byLabel = {} # { "label": Whitelist.Object }
      @byTag = {} # { "tag": [Whitelist.Object, Whitelist.Object] }
      @general = {} # { "tag": [Whitelist.Object, Whitelist.Object] }
      @generalStrings = {} # { "tag": ["rule", "rule"] }
      @add(key, rule) for key, rule of whitelist

    # Returns a Whitelist.Object.
    getByDefault: (key) ->
      @byLabel[@defaults[key]]

    # Returns a Whitelist.Object.
    getByLabel: (label) ->
      @byLabel[label]

    # Returns an array of Whitelist.Object.
    getByTag: (tag) ->
      @byTag[tag]

    # Add a rule to the whitelists.
    # key - label, tag, or *
    # rule - whitelist rule
    add: (key, rule) ->
      if @isLabel(key)
        prevObj = @byLabel[key]
        obj = @parse(rule)
        obj.merge(generalObj) for generalObj in @general[obj.tag] or []
        @byLabel[key] = obj
        # Add to the whitelist by tag.
        @byTag[obj.tag] or= []
        @byTag[obj.tag].push(obj)
        # Remove the previous object if there was one.
        @byTag[prevObj.tag].splice($.inArray(prevObj, @byTag[prevObj.tag]), 1) if prevObj
      else
        throw "Whitelist default '#{key}: #{rule}' must reference a label" unless @isLabel(rule)
        @defaults[key] = rule

    # Adds a general rule that will be applied to all the given tags.
    # rule - whtielist rule
    # tags - an array of tags to attach the rule to
    addGeneralRule: (rule, tags) ->
      obj = @parse(rule)
      for tag in tags
        # Add the new whitelist object if the rule isn't already added.
        @generalStrings[tag] or= []
        if $.inArray(rule, @generalStrings[tag]) == -1
          @generalStrings[tag].push(rule)
          @general[tag] or= []
          @general[tag].push(obj)
          # Add the rule to all existing whitelist objects.
          tagObj.merge(obj) for tagObj in @byTag[tag] or []

    isLabel: (label) ->
      !!label.match(/^[A-Z0-9]/)

    # Parses the given string into a WhitelistObject.
    # e.g. h1#special-h1.title[data-json, style=(background|text-align)] > P
    parse: (rule) ->
      [element, next] = ($.trim(s) for s in rule.split(">"))
      [element, attrs] = ($.trim(s) for s in element.split("["))
      [element, classes...] = ($.trim(s) for s in element.split("."))
      [tag, id] = ($.trim(s) for s in element.split("#"))
      values = {}
      # Handle attributes if there are any.
      # Use [0..-2] to remove the trailing ']'.
      if attrs
        attrs = for s in attrs[0..-2].split(",")
          [attr, v] = $.trim(s).split("=(")
          # Handle values if there are any.
          # Use [0..-2] to remove the trailing ')'.
          values[attr] = ($.trim(s) for s in v[0..-2].split("|")) if v
          attr
      throw "Whitelist next '#{rule}' must reference a label" if next and !@isLabel(next)
      new WhitelistObject(tag, id, classes, attrs, values, next)
