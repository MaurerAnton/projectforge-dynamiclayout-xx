# frozen_string_literal: true
# DynamicLayout Ruby API — generate layout JSON from Ruby code.
#
# Single-file. Zero dependencies (json is stdlib).
# Works on Ruby 2.7+.
#
# Example:
#   page = DynamicLayout::Layout.new('My Page')
#   page.fieldset('Info').label('Hello from Ruby!')
#   page.end_fieldset
#   page.button('ok', 'OK', 'primary', default: true)
#   puts page.to_json

require 'json'

module DynamicLayout
  PRIMARY   = 'primary'
  SECONDARY = 'secondary'
  SUCCESS   = 'success'
  DANGER    = 'danger'
  WARNING   = 'warning'
  INFO      = 'info'

  class Layout
    def initialize(title, uid: nil)
      @title = title
      @uid = uid || "layout_#{object_id}"
      @layout = []
      @actions = []
      @stack = [@layout]
      @counter = 0
    end

    private

    def k(prefix)
      @counter += 1
      "#{prefix}_#{@counter}"
    end

    def top = @stack.last
    def add(el) = (top << el; self)
    def push(el)
      add(el)
      el['content'] = []
      @stack.push(el['content'])
      self
    end
    def pop = (@stack.pop; self)

    public

    # Containers
    def fieldset(title, collapsed: nil)
      el = { 'type' => 'FIELDSET', 'key' => k('fs'), 'title' => title }
      el['collapsed'] = collapsed unless collapsed.nil?
      push(el)
    end
    def end_fieldset = pop
    def end_el = pop
    def row = push({ 'type' => 'ROW', 'key' => k('r') })
    def end_row = pop
    def col(xs: 0, sm: 0, md: 0, lg: 0, xl: 0)
      el = { 'type' => 'COL', 'key' => k('c') }
      l = {}.tap { |h| h['xs'] = xs if xs > 0; h['sm'] = sm if sm > 0; h['md'] = md if md > 0; h['lg'] = lg if lg > 0; h['xl'] = xl if xl > 0 }
      el['length'] = l unless l.empty?
      push(el)
    end
    def end_col = pop
    def group = push({ 'type' => 'GROUP', 'key' => k('g') })
    def inline = push({ 'type' => 'INLINE_GROUP', 'key' => k('ig') })

    # Display
    def label(text) = add({ 'type' => 'LABEL', 'key' => k('l'), 'label' => text })
    def alert(message, color = INFO) = add({ 'type' => 'ALERT', 'key' => k('a'), 'message' => message, 'color' => color })
    def badge(title, color = PRIMARY) = add({ 'type' => 'BADGE', 'key' => k('bd'), 'title' => title, 'color' => color })
    def spacer(px = 20) = add({ 'type' => 'SPACER', 'key' => k('sp'), 'width' => px })
    def progress(pct, label: nil, color: nil)
      el = { 'type' => 'PROGRESS', 'key' => k('pr'), 'progress' => pct }
      el['label'] = label if label
      el['color'] = color if color
      add(el)
    end

    # Inputs
    def input(id, label: '', required: false, data_type: 'STRING', max_length: 0)
      el = { 'type' => 'INPUT', 'key' => k('i'), 'id' => id, 'label' => label }
      el['required'] = true if required
      el['dataType'] = data_type if data_type != 'STRING'
      el['maxLength'] = max_length if max_length > 0
      add(el)
    end
    def textarea(id, label: '', rows: 3) = add({ 'type' => 'TEXTAREA', 'key' => k('ta'), 'id' => id, 'label' => label, 'rows' => rows })
    def checkbox(id, label: '') = add({ 'type' => 'CHECKBOX', 'key' => k('cb'), 'id' => id, 'label' => label })
    def select(id, label, values)
      add({ 'type' => 'SELECT', 'key' => k('s'), 'id' => id, 'label' => label,
            'values' => values.map { |v| { 'id' => v[0], 'displayName' => v[1] } } })
    end
    def radio(id, label, values)
      add({ 'type' => 'RADIOBUTTON', 'key' => k('rb'), 'id' => id, 'label' => label,
            'values' => values.map { |v| { 'id' => v[0], 'displayName' => v[1] } } })
    end
    def rating(id, label: '') = add({ 'type' => 'RATING', 'key' => k('rt'), 'id' => id, 'label' => label })
    def readonly(id, label: '') = add({ 'type' => 'READONLY_FIELD', 'key' => k('ro'), 'id' => id, 'label' => label })

    # Actions
    def button(id, title, color = PRIMARY, default: false, action: nil)
      el = { 'type' => 'BUTTON', 'key' => k('btn'), 'id' => id, 'title' => title, 'color' => color }
      el['default'] = true if default
      el['responseAction'] = action if action
      @actions << el
      self
    end

    # Shortcuts
    def section(title, text) = fieldset(title).label(text).end_fieldset
    def feedback_form
      fieldset('Your Details')
        .input('name', label: 'Name', required: true)
        .input('email', label: 'Email', required: true)
        .textarea('message', label: 'Message', rows: 5)
        .end_fieldset
        .button('send', 'Send', PRIMARY, default: true)
        .button('cancel', 'Cancel', SECONDARY)
    end

    # Output
    def to_h
      pop while @stack.length > 1
      { 'ui' => { 'title' => @title, 'uid' => @uid, 'layout' => @layout,
                   'actions' => @actions.empty? ? nil : @actions,
                   'translations' => {}, 'userAccess' => { 'cancel' => true } } }
    end

    def to_json = JSON.pretty_generate(to_h)
    def to_s = to_json
  end
end
