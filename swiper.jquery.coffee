###
jQuery Swiper Plugin
Based on by Brad Birdsall's Swipe

Licensed under the MIT License
http://opensource.org/licenses/MIT
###

(($, window) ->
  # default settings
  _defaults = 
    debug: false
    start: 0
    speed: 300
    auto: 0
    previewWidth: 0
    interspace: 0
    callback: ->

  # CSS helpers
  $.fn.setTransitionDuration = (duration) ->
    $(this).css 
      webkitTransitionDuration: "#{duration}ms"
      MozTransitionDuration: "#{duration}ms"
      msTransitionDuration: "#{duration}ms"
      OTransitionDuration: "#{duration}ms"
      transitionDuration: "#{duration}ms"

  $.fn.setTranslateX = (translation) ->
    style = $(this).get(0).style
    style.MozTransform = style.webkitTransform = 'translate3d(' + translation + 'px,0,0)'
    style.msTransform  = style.OTransform = 'translateX(' + translation + 'px)'


  class Swiper
    constructor: (el, options) ->
      @options = $.extend {}, _defaults, options
      @index = @options.start
      @delay = @options.auto

      # Reference DOM elements
      @$container = $(el)
      @$el = @$container.children()

      # Static CSS
      @$container.css
        overflow: 'hidden'
        listStyle: 'none'
        margin: 0

      # Prevent user to accidentally select image
      $('img', @$el).css 'user-select', 'none'

      @_init()
      @_start()

      @$el.on
        'touchstart': (e)          => @_onTouchStart.call(@, e)
        'touchmove': (e)           => @_onTouchMove.call(@, e)
        'touchend': (e)            => @_onTouchEnd.call(@, e)
        'webkitTransitionEnd': (e) => @_transitionEnd.call(@, e)
        'msTransitionEnd': (e)     => @_transitionEnd.call(@, e)
        'oTransitionEnd': (e)      => @_transitionEnd.call(@, e)
        'transitionend': (e)       => @_transitionEnd.call(@, e)

      $(window).on 'resize', => @_init.call(@)

      @

    _init: ->
      @$slides = @$el.children()

      return unless @$slides.length > 1

      @$el.css 'text-align', 'left'

      container   = @$container.get(0)
      @width      = if 'getBoundingClientRect' in container then container.getBoundingClientRect().width else container.offsetWidth
      @width      = @width - 2 * @options.previewWidth
      @width      = Math.ceil @width
      @innerWidth = @width - @options.interspace

      return unless @width

      # Hide slider element but keep positioning during setup
      @$container.css 'visibility', 'hidden'

      @$el.width Math.ceil(@$slides.length * (@width))

      @$slides.css
        width:         @innerWidth
        marginLeft:    @options.interspace/2
        marginRight:   @options.interspace/2
        display:       'inline-block'
        verticalAlign: 'top'
        textAlign:     'center'

      # Set start position and force translate to remove initial flickering
      @_slide @index, 0

      @$container.css 'visibility', 'visible'

    _slide: (index, duration = @options.speed) ->
      @translation = @options.previewWidth - index * @width

      # jQuery can't set transform CSS property, bach to plain javascript
      @$el.setTranslateX(@translation)
      
      # Set duration speed (0 represents 1 to-1 scrolling) and translate
      @$el.setTransitionDuration duration 
      
      @index = index

    _start: ->
      @interval =
        if @delay then setTimeout ( =>
            @next @delay
          ), @delay
        else 0

    _transitionEnd: (e) ->
      @_start() if @delay
      @options.callback.call @$container, @index, @$slides.eq(@index)

    _onTouchStart: (e) ->
      e = e.originalEvent

      @start =
        pageX: e.touches[0].pageX, # Get touch coordinates
        pageY: e.touches[0].pageY, # for delta calculations in onTouchMove
        
        time: Number new Date() # Set initial timestamp of touch sequence

      @isScrolling = undefined
      @deltaX      = 0
      @$el.setTransitionDuration 0 # 1-to-1 touch movement

      e.stopPropagation()

    _onTouchMove: (e) ->
      e = e.originalEvent

      return if e.touches.length > 1 # Exit if pinch

      @deltaX = e.touches[0].pageX - @start.pageX

      # Determine if scrolling test has run - one time test
      if typeof @isScrolling == 'undefined'
        @isScrolling = !!(@isScrolling || Math.abs(@deltaX) < Math.abs(e.touches[0].pageY - @start.pageY))

      return if @isScrolling # If user is not trying to scroll vertically
      
      e.preventDefault()
      clearTimeout @interval # Cancel auto slide

      # Increase resistance if first or last slide
      firstSlidingLeft = !@index && @deltaX > 0
      lastSlidingRight = @index == @$slides.length - 1 && @deltaX < 0
      resistance = if firstSlidingLeft || lastSlidingRight then Math.abs(@deltaX) / @width + 1 else 1
      @deltaX = @deltaX / resistance

      @$el.setTranslateX(@deltaX + @translation)

    _onTouchEnd: (e) ->
      e = e.originalEvent

      # Determine if slide attempt triggers next/prev slide
      # If slide duration is less than 250ms AND if slide amt is greater than 20px OR if slide amt is greater than half the width
      isValidSlide = Number(new Date()) - @start.time < 250 && Math.abs(@deltaX) > 20 || Math.abs(@deltaX) > @width/2

      # Determine if slide attempt is past start and end
      # If first slide and slide amt is greater than 0 OR if last slide and slide amt is less than 0
      isPastBounds = !@index && @deltaX > 0 || @index == @$slides.length - 1 && @deltaX < 0

      # If not scrolling vertically
      unless @isScrolling
        direction = if @deltaX < 0 then 1 else -1
        val       = if isValidSlide && !isPastBounds then direction else 0 
        @_slide @index + val, @options.speed

      e.stopPropagation()


    # Public methods

    prev: (delay) ->
      # Cancel next scheduled automatic transition, if any
      @delay = delay || 0
      clearTimeout(@interval)

      # if not at first slide
      @_slide @index-1, @options.speed if @index

    next: (delay) ->
      # Cancel next scheduled automatic transition, if any
      @delay = delay || 0
      clearTimeout @interval 

      if @index < @$slides.length - 1 # unless last slide
        @_slide @index+1, @options.speed
      else # if last slide
        @_slide 0, @options.speed

    stop: ->
      @delay = 0
      clearTimeout @interval

    resume: ->
      @delay = @options.auto || 0
      @_start()

    goto: (index) ->
      @_slide index

    position: (to) ->
      if to? # Setter
        @goto to
      else # Getter
        @index


  # jQuery plugin
  $.fn.swiper = (options) ->
    args = Array.prototype.slice.call(arguments, 1)
    r = []
    @each ->
      $el = $(this)
      if typeof options == 'string'
        plugin = $el.data 'swiper'
        r.push plugin[options].apply(plugin, args)
      else if !$el.data 'swiper'
        $el.data 'swiper', new Swiper(this, options)

    if r.length == 1
      return r[0]
    else if r.length
      return r
    else 
      return @

) jQuery, window