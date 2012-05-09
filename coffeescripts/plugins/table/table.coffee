define ["jquery.custom", "core/browser", "core/helpers"], ($, Browser, Helpers) ->
  class Table
    constructor: (options = {}) ->
      @options =
        table: [2, 3]
      $.extend(@options, options)

    register: (@api) ->

    getUI: (ui) ->
      insertTable = ui.button(action: "insertTable", title: "Insert Table (Ctrl+Shift+T)", icon: "image.png")
      addRowAbove = ui.button(action: "addRowAbove", title: "Add Row Above (Ctrl+Shift+Enter)", icon: "image.png")
      addRowBelow = ui.button(action: "addRowBelow", title: "Add Row Below (Ctrl+Shift+Enter)", icon: "image.png")
      deleteRow = ui.button(action: "deleteRow", title: "Delete Row", icon: "image.png")
      addColLeft = ui.button(action: "addColLeft", title: "Add Column Left (Ctrl+9)", icon: "image.png")
      addColRight = ui.button(action: "addColRight", title: "Add Column Right (Ctrl+0)", icon: "image.png")
      deleteCol = ui.button(action: "deleteCol", title: "Delete Col", icon: "image.png")
      deleteTable = ui.button(action: "deleteTable", title: "Delete Table", icon: "image.png")
      return {
        "toolbar:default": "table"
        table: insertTable
        "context:table": [addRowAbove, addRowBelow, deleteRow, addColLeft, addColRight, deleteCol, deleteTable]
      }

    getActions: ->
      return {
        insertTable: @insertTable
        deleteTable: (e) => @deleteTable()
        addRowAbove: Helpers.pass(@addRow, true, this)
        addRowBelow: Helpers.pass(@addRow, false, this)
        deleteRow: @deleteRow
        addColLeft: Helpers.pass(@addCol, true, this)
        addColRight: Helpers.pass(@addCol, false, this)
        deleteCol: @deleteCol
      }

    getKeyboardShortcuts: ->
      return {
        "ctrl.shift.t": @table
        "ctrl.shift.enter": Helpers.pass(@addRow, true, this)
        "ctrl.enter": Helpers.pass(@addRow, false, this)
        "ctrl.9": Helpers.pass(@addCol, true, this)
        "ctrl.0": Helpers.pass(@addCol, false, this)
      }

    insertTable: =>
      # Build the table.
      $table = $('<table id="INSERTED_TABLE"></table>')
      $tbody = $("<tbody/>").appendTo($table)
      $td = $("<td>&nbsp;</td>")
      $tr = $("<tr/>")
      $tr.append($td.clone()) for i in [1..@options.table[1]]
      $tbody.append($tr.clone()) for i in [1..@options.table[0]]

      # Add the table.
      @api.paste($table[0])

      # Set the cursor inside the first td of the table. Then remove the id.
      $table = $("#INSERTED_TABLE")
      @api.selectEndOfTableCell($table.find("td")[0])
      $table.removeAttr("id")

      # Update.
      @update()

    # Deletes the entire table. If no table is passed in, it attempts to the
    # find a table that contains the range.
    deleteTable: (table) =>
      table = table or @api.getParentElement("table")
      if table
        $table = $(table)
        # In IE, when the table is destroyed, the cursor is placed at the
        # beginning of the next text.
        # In W3C browsers, the cursor is lost. Instead of destroying the table,
        # we replace it with a paragraph and set the cursor there. Note that
        # this doesn't work in IE because selecting the end of the inserted
        # paragraph places the cursor at the start of the next element.
        if Browser.hasW3CRanges
          $p = $("<p>#{Helpers.zeroWidthNoBreakSpace}</p>")
          $table.replaceWith($p)
          @api.selectEndOfElement($p[0])
        else
          $table.remove()
        @update()


    # Inserts a new row. The first argument specifies whether the row should
    # appear before or after the current row.
    addRow: (before) =>
      cell = @getCell()
      if cell
        $cell = $(cell)
        $tr = $cell.parent("tr")
        $tds = $tr.children()
        $newTr = $("<tr/>")
        $newTr.append($("<td>#{Helpers.zeroWidthNoBreakSpace}</td>")) for i in [1..$tds.length]
        $tr[if before then "before" else "after"]($newTr)
        # Put the cursor in the first td of the newly added tr.
        @api.selectEndOfTableCell($newTr.children("td")[0])
        @update()

    # Deletes a row and moves the caret to the first cell in the next row.
    # If no next row, moves caret to first cell in previous row. If no more
    # rows, deletes the table.
    deleteRow: =>
      tr = @api.getParentElement("tr")
      if tr
        $tr = $(tr)
        $defaultTr = $tr.next("tr")
        $defaultTr = $tr.prev("tr") unless $defaultTr.length > 0
        if $defaultTr.length > 0
          $tr.remove()
          @api.selectEndOfTableCell($defaultTr.children()[0])
        else
          @deleteTable($tr.closest("table")[0])
        @update()

    # inserts a new column. The first argument specifies whether the column
    # should appear before or after the current column.
    addCol: (before) =>
      cell = @getCell()
      if cell
        $cell = $(cell)
        @eachCellInCol($cell, ->
          newCell = $(this).clone(false).html(Helpers.zeroWidthNoBreakSpace)
          $(this)[if before then "before" else "after"](newCell)
        )
        $nextCell = $cell[if before then "prev" else "next"]($cell.tagName())
        # Put the cursor in the newly added column beside the original cell.
        @api.selectEndOfTableCell($nextCell[0])
        @update()

    # deletes column and moves cursor to right. If no right cell, to left.
    # If no left or right, it deletes the whole table.
    deleteCol: =>
      cell = @getCell()
      if cell
        $cell = $(cell)
        $defaultCell = $cell.next()
        $defaultCell = $cell.prev() unless $defaultCell.length > 0
        if $defaultCell.length > 0
          @eachCellInCol($cell, -> $(this).remove())
          @api.selectEndOfTableCell($defaultCell[0])
        else
          @deleteTable($cell.closest("table"))
        @update()

    # Find the currently selected cell (i.e. td or th).
    getCell: ->
      @api.getParentElement((el) ->
        tag = $(el).tagName()
        tag == 'td' or tag == 'th'
      )

    # This function iterates through a single column of cells based on the
    # cell passed in.
    eachCellInCol: (cell, fn) ->
      $cell = $(cell)
      $tr = $cell.parent("tr")
      $cells = $tr.children()
      for i in [0..$cells.length-1]
        break if $cells[i] == $cell[0]
      for row in $tr.parent().children("tr")
        fn.apply($(row).children()[i])

    # NOTE: Leaving this here for now because I'm not sure if we'll need it.
    # Change the tag of the current cell (th or td are expected values).
    #tag: (tag) ->
      #cell = @getCell()
      #if cell
        #$cell = cell
        #cellTag = $cell.tagName()
        #if cellTag != tag
          #newCell($("<#{tag}/>").html($cell.html()))
          #$cell.replaceWith(newCell)
          #@api.selectEndOfTableCell(newCell.get(0))

    update: ->
      # In Firefox, when a user clicks on the toolbar to style, the
      # editor loses focus. Instead, the focus is set on the toolbar
      # button (even though unselectable="on"). Whenever the user
      # types a character, it inserts it into the editor, but also
      # presses the toolbar button. This can result in alternating
      # behaviour. For example, if I click on the list button. When
      # I start typing, it will toggle lists on and off.
      # This cannot be called for IE because it will cause the window to scroll
      # and jump. Hence this is only for Firefox.
      @api.el.focus() if Browser.isMozilla
      @api.update()

  return Table
