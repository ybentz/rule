Rule = @Rule
expect = @expect
window = @window
document = @document

describe 'Rule', ->

  makeNode = (string) ->
    container = document.createElement 'div'
    container.innerHTML = string
    container.childNodes

  asString = (object) ->
    container = document.createElement 'div'
    if object instanceof Array
      container.appendChild(node.cloneNode(true)) for node in object
      container.innerHTML
    else
      object.outerHTML

  before (done) ->
    if module? and @module isnt module
      Rule = require('../rule')
      expect = require('expect.js')
      window = require('sub').window
      document = window.document
      Rule.env = window
    do done

  describe '::split', ->
    selectors = [undefined, 'div', '.a', '.a-b', '["a=b"]', 'div:nth-child(n)', 'div > span', 'div + span']
    attributes = [undefined, 'a', 'a-b']
    positions = [undefined, '-', '+', '=', '<', '>']

    it "should return [selector, attribute, position]", ->
      for selector in selectors
        for attribute in attributes
          for position in positions
            expect(Rule.split (selector ? '')+(if attribute then '@'+attribute else '')+(position ? '')).to.be.eql [selector, attribute, position]

  describe '::parse', ->
    it "should return the parsed result of the function bound to data", ->
      expect(Rule.parse (->@), 'a').to.be.eql 'a'
      expect(Rule.parse (->@a), {a:'b'}).to.be.eql 'b'
      expect(Rule.parse (->->@a), {a:'b'}).to.be.eql 'b'
      a = -> @a
      expect(Rule.parse (->a), {a:'b'}).to.be.eql 'b'

    it "should return the array with each array item parsed", ->
      a = document.createTextNode('a')
      b = document.createTextNode('b')
      c = document.createTextNode('c')
      expect(Rule.parse [a,b,c]).to.be.eql [a,b,c]
      expect(Rule.parse [(->@a),(->@b),(->@c)], {a: a, b: b, c: c}).to.be.eql [a,b,c]

    it "should return the result of the rule's render function", ->
      rule = new Rule
        '.a': ->@
      selection = makeNode '<div><span class="a"></div>'
      Rule.parse rule, 'b', selection: selection
      expect(asString selection).to.be.equal asString makeNode '<div><span class="a">b</div>'
      selection = makeNode '<div><span class="a"></div>'
      rule.template = selection
      expect(asString Rule.parse rule, 'b').to.be.eql asString makeNode '<div><span class="a">b</span></div>'

    it "should return the passed in HTMLElement", ->
      el = makeNode('<div>')[0]
      expect(Rule.parse el).to.be el

    it "should return the passed in node array as an array", ->
      el = makeNode('<div>')
      expect((Rule.parse el)).to.eql el
      el = makeNode('<div></div><span></span>')
      expect((Rule.parse el)).to.eql el

    it "should return undefined", ->
      expect(Rule.parse undefined).to.be undefined

    it "should return null", ->
      expect(Rule.parse null).to.be null

    it "should return the object's toString results", ->
      expect(Rule.parse true).to.be 'true'
      expect(Rule.parse false).to.be 'false'
      expect(Rule.parse 'abc').to.be 'abc'
      expect(Rule.parse 123).to.be '123'
      O = ->
      O.prototype.toString = -> 'test'
      o = new O
      expect(Rule.parse o).to.be 'test'
      o = {toString: -> 'test'}
      expect(Rule.parse o).to.be 'test'

    it "should return the results of the object compiled as a new rule with selection as the template", ->
      rule =
        '.a': ->@
      selection = makeNode '<div><span class="a"></div>'
      Rule.parse rule, 'b', selection: selection
      expect(asString selection).to.be.eql asString makeNode '<div><span class="a">b</div>'

  describe '::add', ->

    it "should prepend the attribute with content", ->
      e = makeNode('<div class="b">')
      expect(asString Rule.add 'a', e, 'class', '-').to.be.eql asString makeNode('<div class="a b">')

    it "should append the attribute with content", ->
      e = makeNode('<div class="a">')
      expect(asString Rule.add 'b', e, 'class', '+').to.be.eql asString makeNode('<div class="a b">')

    it "should add before the attribute with content", ->
      e = makeNode('<div class="b">')
      expect(asString Rule.add 'a', e, 'class', '<').to.be.eql asString makeNode('<div class="ab">')

    it "should add after the attribute with content", ->
      e = makeNode('<div class="a">')
      expect(asString Rule.add 'b', e, 'class', '>').to.be.eql asString makeNode('<div class="ab">')

    it "should set the attribute to content", ->
      e = makeNode('<div class="b">')
      expect(asString Rule.add 'a', e, 'class').to.be.eql asString makeNode('<div class="a">')

    it "should add content before selection", ->
      c = makeNode('<div><span></span></div>')
      r = Rule.add 'a', c, null, '<'
      expect(asString c).to.be.eql asString makeNode('<div>a<span></span></div>')
      expect(asString r).to.be.eql asString makeNode('<div>a<span></span></div>')

    it "should add content after selection", ->
      c = makeNode('<div><span></span></div>')
      r = Rule.add 'a', c, null, '>'
      expect(asString c).to.be.eql asString makeNode('<div><span></span>a</div>')
      expect(asString r).to.be.eql asString makeNode('<div><span></span>a</div>')

    it "should add content as the first child of selection", ->
      c = makeNode('<div>')[0]
      e = c.appendChild makeNode('<span>')[0]
      f = e.appendChild makeNode('<span>')[0]
      r = Rule.add 'a', [f], null, '-'
      expect(asString r).to.be.eql asString makeNode('a<span></span>')
      expect(asString c).to.be.eql asString makeNode('<div><span>a<span></span></span></div>')

    it "should add content as the last child of selection", ->
      c = makeNode('<div>')[0]
      e = c.appendChild makeNode('<span>')[0]
      f = e.appendChild makeNode('<span>')[0]
      r = Rule.add 'a', [f], null, '+'
      expect(asString c).to.be.eql asString makeNode('<div><span><span></span>a</span></div>')
      expect(asString r).to.be.eql asString makeNode('<span></span>a')

    it "should set content to replace selection", ->
      c = makeNode('<div>')[0]
      e = c.appendChild makeNode('<span>')[0]
      r = Rule.add 'a', [e], null, '='
      expect(asString c).to.be.eql asString makeNode('<div>a</div>')
      expect(asString r).to.be.eql 'a'

    it "should set content as the only child of selection", ->
      c = makeNode('<div>')[0]
      e = c.appendChild makeNode('<span>')[0]
      f = e.appendChild makeNode('<span>')[0]
      r = Rule.add 'a', [e]
      expect(asString c).to.be.eql asString makeNode('<div><span>a</span></div>')
      expect(asString r).to.be.eql asString makeNode('<span>a</span>')

    it "should set array of content as children of selection", ->
      c = makeNode('<div>')
      r = Rule.add ['a','b','c','d'], c
      expect(asString c).to.be.eql asString makeNode('<div>abcd</div>')
      expect(asString r).to.be.eql asString makeNode('<div>abcd</div>')

    it "should set joined array of content as attribute", ->
      c = makeNode('<div>')
      r = Rule.add ['a','b','c','d'], c, 'class'
      expect(asString r).to.be.eql asString makeNode('<div class="abcd"></div>')

  describe '.render', ->

    # From template and application
    it "should clone a template and return that object", ->
      template = makeNode('<div>')
      rule = new Rule
        '': 'test',
        template
      expect(asString rule.render()).to.be.eql asString makeNode('<div>test</div>')
      expect(asString template).to.be.eql asString makeNode('<div>')

    it "should alter a template and return that object", ->
      template = makeNode('<div>')
      rule = new Rule
        '': 'test'
      expect(asString rule.render {}, template).to.be.eql asString makeNode('<div>test</div>')
      expect(template).to.be.equal template

    it "should allow text nodes in the template", ->
      template = makeNode('<div>test<span class="a"></span>test</div>')
      rule = new Rule
        '.a': 'test'
      expect(asString rule.render {}, template).to.be.eql asString makeNode('<div>test<span class="a">test</span>test</div>')
      expect(template).to.be.equal template

    it "should execute a template function and render on that generated template", ->
      template = -> makeNode('<div>')
      rule = new Rule
        '': 'test'
      expect(asString rule.render {}, template).to.be.eql asString makeNode('<div>test</div>')
      expect(template).to.be.equal template

    # Attributes
    it "should set the attributes of the parent", ->
      rule = new Rule
        '@class': 'test',
        makeNode('<div>')
      expect(asString rule.render()).to.be.eql asString makeNode('<div class="test"></div>')

    it "should set the attributes of a selection", ->
      rule = new Rule
        'span@class': 'test',
        makeNode('<div><span></span></div>')
      expect(asString rule.render()).to.be.eql asString makeNode('<div><span class="test"></span></div>')

    it "should set the attributes of a subparent", ->
      rule = new Rule
        'span':
          '@class': 'test',
        makeNode('<div><span></span></div>')
      expect(asString rule.render()).to.be.eql asString makeNode('<div><span class="test"></span></div>')

    it "should not set the attribute if the content is undefined", ->
      rule = new Rule
        '@class': 'test',
        makeNode('<div>')
      expect(asString rule.render()).to.be.eql asString makeNode('<div class="test"></div>')

    # Data insertion
    it "should set the contents based on a data object", ->
      rule = new Rule
        '': ->@a,
        makeNode('<div>')
      expect(asString rule.render {a: 'test'}).to.be.eql asString makeNode('<div>test</div>')

    # Selections
    it "should set the contents of a simple tag selection", ->
      rule = new Rule
        'span': 'test',
        makeNode('<div><span></span></div>')
      expect(asString rule.render()).to.be.eql asString makeNode('<div><span>test</span></div>')

    it "should replace the contents of a simple tag selection", ->
      rule = new Rule
        'span': 'test',
        makeNode('<div><span><a>a</a><a>b</a><a>c</a></span></div>')
      expect(asString rule.render()).to.be.eql asString makeNode('<div><span>test</span></div>')

    it "should not find the selection and do nothing", ->
      rule = new Rule
        'span': 'x',
        makeNode('<div><a></a></div>')
      expect(asString rule.render()).to.be.eql asString makeNode('<div><a></a></div>')

    it "should set the contents of a simple class selection", ->
      rule = new Rule
        '.simple': 'test',
        makeNode('<div><a><span>a</span><h1>x</h1><span class="simple">b</span><span>c</span></a></div>')
      expect(asString rule.render()).to.be.eql asString makeNode('<div><a><span>a</span><h1>x</h1><span class="simple">test</span><span>c</span></a></div>')

    # Multiple Selections
    it "should set the contents of multiple selections", ->
      rule = new Rule
        'span': 'test',
        makeNode('<div><span></span><span></span></div>')
      expect(asString rule.render()).to.be.eql asString makeNode('<div><span>test</span><span>test</span></div>')

    it "should set the contents of multiple selections on different levels", ->
      rule = new Rule
        'span': 'test',
        makeNode('<div><span></span><a><span></span></a></div>')
      expect(asString rule.render()).to.be.eql asString makeNode('<div><span>test</span><a><span>test</span></a></div>')

    # Parent Positioning
    it "should add content in the right order and return the added siblings", ->
      rule = new Rule
        '': 'c'
        '>': 'd'
        '<': 'b'
        makeNode('<span>x</span>')
      expect(asString rule.render()).to.be.eql asString makeNode('<span>bcd</span>')

    # Selection Positioning
    it "should add content before and after a selection", ->
      rule = new Rule
        'span-': ->makeNode('<a>')[0]
        makeNode('<div><span></span></div>')
      expect(asString rule.render()).to.be.eql asString makeNode('<div><a></a><span></span></div>')
      rule = new Rule
        'span+': ->makeNode('<a>')[0]
        makeNode('<div><span></span></div>')
      expect(asString rule.render()).to.be.eql asString makeNode('<div><span></span><a></a></div>')

    it "should add content to the start and end of a selection", ->
      rule = new Rule
        'span<': ->makeNode('<a>')[0]
        makeNode('<div><span><p></p></span></div>')
      expect(asString rule.render()).to.be.eql asString makeNode('<div><span><a></a><p></p></span></div>')
      rule = new Rule
        'span>': ->makeNode('<a>')[0]
        makeNode('<div><span><p></p></span></div>')
      expect(asString rule.render()).to.be.eql asString makeNode('<div><span><p></p><a></a></span></div>')

    it "should replace a selection", ->
      rule = new Rule
        'span=': ->makeNode('<a>')[0]
        makeNode('<div><span><p></p></span></div>')
      expect(asString rule.render()).to.be.eql asString makeNode('<div><a></a></div>')

    it "should remove multiple selections", ->
      rule = new Rule
        'span=': ->''
        'span': ->'hi'
        makeNode('<div><span><p>test</p></span><span><h1>title</h1></span><span><a>link</a></span></div>')
      expect(asString rule.render()).to.be.eql asString makeNode('<div></div>')

    it "should replace a selection and not match again", ->
      pRan = false
      rule = new Rule
        'span=': ->''
        'span': -> pRan = true
        makeNode('<div><span><p></p></span></div>')
      rule.render()
      expect(pRan).to.be.eql(false)

    it "should replace a selection and not execute replaced match", ->
      pRan = false
      rule = new Rule
        'span=': ->makeNode('<a>')[0]
        'p': -> pRan = true
        makeNode('<div><span><p></p></span></div>')
      rule.render()
      expect(pRan).to.be.eql(false)

    # Multiple Selection Positioning
    it "should add content before and after multiple selections", ->
      rule = new Rule
        'span-': ->makeNode('<a>')[0]
        makeNode('<div><span></span><span></span></div>')
      expect(asString rule.render()).to.be.eql asString makeNode('<div><a></a><span></span><a></a><span></span></div>')
      rule = new Rule
        'span+': ->makeNode('<a>')[0]
        makeNode('<div><span></span><span></span></div>')
      expect(asString rule.render()).to.be.eql asString makeNode('<div><span></span><a></a><span></span><a></a></div>')

    it "should add content to the start and end of multiple selections", ->
      rule = new Rule
        'span<': ->makeNode('<a>')[0]
        makeNode('<div><span><p></p></span><span><h1></h1></span></div>')
      expect(asString rule.render()).to.be.eql asString makeNode('<div><span><a></a><p></p></span><span><a></a><h1></h1></span></div>')
      rule = new Rule
        'span>': ->makeNode('<a>')[0]
        makeNode('<div><span><p></p></span><span><h1></h1></span></div>')
      expect(asString rule.render()).to.be.eql asString makeNode('<div><span><p></p><a></a></span><span><h1></h1><a></a></span></div>')

    it "should replace multiple selections", ->
      rule = new Rule
        'span=': ->makeNode('<a>')[0]
        makeNode('<div><span><p></p></span><span><h1></h1></span></div>')
      expect(asString rule.render()).to.be.eql asString makeNode('<div><a></a><a></a></div>')

    # Selection Attributes
    it "should alter attributes of a selection", ->
      rule = new Rule
        'span@class': 'test',
        makeNode('<div><span></span></div>')
      expect(asString rule.render()).to.be.eql asString makeNode('<div><span class="test"></span></div>')

    it "should alter attributes of multiple selections", ->
      rule = new Rule
        'span@class': 'test'
        makeNode('<div><span></span><span></span></div>')
      expect(asString rule.render()).to.be.eql asString makeNode('<div><span class="test"></span><span class="test"></span></div>')

    # Sub Rules
    it "should select into a new scope and apply a new rule object to it", ->
      rule = new Rule
        'a':
          'span': 'c',
        makeNode('<div><a><span>b</span></a></div>')
      expect(asString rule.render()).to.be.eql asString makeNode('<div><a><span>c</span></a></div>')

    it "should select into a new scope and not find the selection in the new context", ->
      rule = new Rule
        'a':
          'div': 'c',
        makeNode('<div><a><span>b</span></a><div></div></div>')
      expect(asString rule.render()).to.be.eql asString makeNode('<div><a><span>b</span></a><div></div></div>')

    it "should select into a new scope and do nothing", ->
      rule = new Rule
        '': {},
        makeNode('<div>')
      expect(asString rule.render()).to.be.eql asString makeNode('<div></div>')

    it "should remove multiple selections", ->
      rule = new Rule
        '.a=': ''
        makeNode('<div><span class="a">b</span><span class="a">c</span></div>')
      expect(asString rule.render()).to.be.eql asString makeNode('<div></div>')

    it "should remove a selection then attempt to add to it", ->
      rule = new Rule
        'a':
          '=': ''
          '': 'c',
        makeNode('<div><a>b</a></div>')
      expect(asString rule.render()).to.be.eql asString makeNode('<div></div>')

    it "should not remove a selection then add to it", ->
      rule = new Rule
        'a':
          '=': null
          '': 'c',
        makeNode('<div><a>b</a></div>')
      expect(asString rule.render()).to.be.eql asString makeNode('<div><a>c</a></div>')

    it "should remove a selection then attempt to add an attribute to it", ->
      rule = new Rule
        'a':
          '=': ''
          '@href': 'c',
        makeNode('<div><a>b</a></div>')
      expect(asString rule.render()).to.be.eql asString makeNode('<div></div>')

    it "should remove a selection then attempt to add to a child of it", ->
      rule = new Rule
        'a':
          '=': ''
          'span': 'c',
        makeNode('<div><a><span></span></a></div>')
      expect(asString rule.render()).to.be.eql asString makeNode('<div></div>')

    it "should add a sibling to a selection then add to the root", ->
      rule = new Rule
        'a':
          '+': ->makeNode('<a>')[0]
          '': 'c'
        makeNode('<div><a>b</a></div>')
      expect(asString rule.render()).to.be.eql asString makeNode('<div><a>c</a><a></a></div>')

    # Arrays
    it "should set the contents to the result of an array of functions", ->
      rule = new Rule
        'span': [(->@a), (->@b), (->@c)],
        makeNode('<div><span></span></div>')
      expect(asString rule.render {a:'x',b:'y',c:'z'}).to.be.eql asString makeNode('<div><span>xyz</span></div>')

    it "should set the contents to the result of a function that returns an array of functions", ->
      rule = new Rule
        'span': -> ((i)->i*@x).bind(@, i) for i in [1...5],
        makeNode('<div><span></span></div>')
      expect(asString rule.render {x: 2}).to.be.eql asString makeNode('<div><span>2468</span></div>')

    # Class extension
    it "should extend the Rule class then render off it", ->
      class Test extends Rule
        rule:
          '': 'test'
        template:
          makeNode('<div></div>')
      expect(asString (new Test).render()).to.be.eql asString makeNode('<div>test</div>')

    it "should extend the Rule class while providing a rule property", ->
      class Test extends Rule
        rule:
          '': 'test'
        template:
          makeNode('<div></div>')
      test = new Test
        '>': 'test2'
      expect(asString test.render()).to.be.eql asString makeNode('<div>test2</div>')

    it "should extend the Rule class then set the contents of a nested element", ->
      class Test extends Rule
        rule:
          '.test':
            '': 'test'
        template:
          makeNode('<div><p><span class="test"></span></p></div>')
      expect(asString (new Test).render()).to.be.eql asString makeNode('<div><p><span class="test">test</span></p></div>')

    it "should extend the Rule class then replace the contents of a nested element", ->
      class Test extends Rule
        rule:
          '.test':
            '=': 'test'
        template:
          makeNode('<div><p><span class="test"></span></p></div>')
      expect(asString (new Test).render()).to.be.eql asString makeNode('<div><p>test</p></div>')

    it "should extend an extended Rule, and then apply both rules in order of oldest first", ->
      class Test extends Rule
        rule:
          '.test': 'X'
          '.test2': 'X'
        template:
          makeNode('<div><p><span class="test"></span><span class="test2"></span></p></div>')
      class Test2 extends Test
        rule:
          '.test2': 'Y'
      expect(asString (new Test2).render()).to.be.eql asString makeNode('<div><p><span class="test">X</span><span class="test2">Y</span></p></div>')

    it "should extend an extended Rule, and and overwrite the order of the overwritten rule", ->
      class Test extends Rule
        rule:
          '.test': 'X'
          '.test2': 'Y'
        template:
          makeNode('<div><p><span class="test test2"></span></p></div>')
      class Test2 extends Test
        rule:
          '.test': 'X'
      expect(asString (new Test2).render()).to.be.eql asString makeNode('<div><p><span class="test test2">X</span></p></div>')

    it "should extend an extended Rule twice, and then apply both rules in order of oldest first", ->
      class Test extends Rule
        rule:
          '.test': 'X'
          '.test2': 'X'
          '.test3': 'X'
        template:
          makeNode('<div><p><span class="test"></span><span class="test2"></span><span class="test3"></span></p></div>')
      class Test2 extends Test
        rule:
          '.test2': 'Y'
          '.test3': 'Y'
      class Test3 extends Test2
        rule:
          '.test3': 'Z'
      expect(asString (new Test3).render()).to.be.eql asString makeNode('<div><p><span class="test">X</span><span class="test2">Y</span><span class="test3">Z</span></p></div>')

    it "should extend an extended Rule, and then apply just the childmost overwritten rule", ->
      class Test extends Rule
        rule:
          '.test<': 'X'
        template:
          makeNode('<div><p><span class="test"></span></p></div>')
      class Test2 extends Test
        rule:
          '.test<': 'Y'
      expect(asString (new Test2).render()).to.be.eql asString makeNode('<div><p><span class="test">Y</span></p></div>')

    it "should extend the Rule class and overwrite the parse function", ->
      class Test extends Rule
        @parse: (rule, data, selection, context) ->
          if typeof rule is 'string' or rule instanceof String
            return rule+'suffix'
          super
      rule = new Test
        '.test': 'X'
        makeNode('<div><span class="test"></span></div>')
      expect(asString rule.render()).to.be.eql asString makeNode('<div><span class="test">Xsuffix</span></div>')

    it "should extend the Rule class and overwrite the parse function and parse other rules that haven't been blocked", ->
      class Class
      class Test extends Rule
        @parse: (rule, data, selection, context) ->
          if rule instanceof Class
            return 'class'
          super
      rule = new Test
        '.test': new Class
        '.test2': 'test'
        makeNode('<div><span class="test"></span><span class="test2"></span></div>')
      expect(asString rule.render()).to.be.eql asString makeNode('<div><span class="test">class</span><span class="test2">test</span></div>')

    it "should extend the Rule class with a custom parser and use that parser when a new rule is created from a rule object", ->
      class Test extends Rule
        @parse: (rule, data, selection, context) ->
          if typeof rule is 'string' or rule instanceof String
            return rule+'suffix'
          super
      rule = new Test
        '.test':
          '': 'X'
        makeNode('<div><span class="test"></span></div>')
      expect(asString rule.render()).to.be.eql asString makeNode('<div><span class="test">Xsuffix</span></div>')

    it "should fail a rule without crashing", ->
      rule = new Rule
        '@class+': -> a.b
        makeNode('<div>')
      # Temporarily silence console.error
      temp = console.error
      console.error = ->
      expect(asString rule.render()).to.not.throwError
      console.error = temp
