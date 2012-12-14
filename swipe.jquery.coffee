###
jQuery Swipe Plugin

Based on Swipe 1.0 by Brad Birdsall
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
      # Get slides
      @$slides = @$el.children()

      # Return if their are less than 2 slides
      return unless @$slides.length > 1

      # Determine width of each slide
      container   = @$container.get(0)
      @width      = if 'getBoundingClientRect' in container then container.getBoundingClientRect().width else container.offsetWidth
      @width      = @width - 2 * @options.previewWidth
      @width      = Math.ceil @width
      @innerWidth = @width - @options.interspace

      # Return if measurement fails
      return unless @width

      # Hide slider element but keep positioning during setup
      @$container.css 'visibility', 'hidden'

      # Dynamic CSS
      @$el.width Math.ceil(@$slides.length * (@width))

      @$slides.css
        width: @innerWidth
        marginLeft: @options.interspace/2
        marginRight: @options.interspace/2
        display: 'inline-block'
        verticalAlign: 'top'

      # Set start position and force translate to remove initial flickering
      @slide @index, 0

      # Show slider
      @$container.css 'visibility', 'visible'

    slide: (index, duration = @options.speed) ->

      @translation = @options.previewWidth - index * @width

      # jQuery can't set transform CSS property, bach to plain javascript
      style              = @$el.get(0).style
      style.MozTransform = style.webkitTransform = 'translate3d(' + @translation + 'px,0,0)'
      style.msTransform  = style.OTransform = 'translateX(' + @translation + 'px)'
      
      # Set duration speed (0 represents 1 to-1 scrolling) and translate
      @$el.css 
        webkitTransitionDuration: "#{duration} ms"
        MozTransitionDuration: "#{duration} ms"
        msTransitionDuration: "#{duration} ms"
        OTransitionDuration: "#{duration} ms"
        transitionDuration: "#{duration} ms"
      
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
        # Get touch coordinates for delata calculations in onTouchMove
        pageX: e.touches[0].pageX,
        pageY: e.touches[0].pageY,

        # Set initial timestamp of touch sequence
        time: Number new Date()

      # Used for testing first onTouchMove event
      @isScrolling = undefined

      # Reset deltaX
      @deltaX = 0

      # Set transition time to 0 for 1-to-1 touch movement
      @$el.css
        MozTransitionDuration: '0ms'
        webkitTransitionDuration: '0ms'

      e.stopPropagation()

    _onTouchMove: (e) ->
      e = e.originalEvent

      # Ensure swiping with one touch and not pinching
      return if e.touches.length > 1 || e.scale && e.scale != 1

      @deltaX = e.touches[0].pageX - @start.pageX

      # Determine if scrolling test has run - one time test
      if typeof @isScrolling == 'undefined'
        @isScrolling = !!(@isScrolling || Math.abs(@deltaX) < Math.abs(e.touches[0].pageY - @start.pageY))

      # If user is not trying to scroll vertically
      unless @isScrolling
        e.preventDefault()

        # Cancel slideshow
        clearTimeout @interval

        # Increase resistance if first or last slide
        # If first slide and sliding left OR last slide and sliding right AND sliding at all
        condition = !@index && @deltaX > 0 || @index == @$slides.length - 1 && @deltaX < 0
        # Determine resistance level or no resistance
        div = if condition then Math.abs(@deltaX) / @width + 1 else 1
        @deltaX = @deltaX / div


        style = @$el.get(0).style
        style.MozTransform = style.webkitTransform = 'translate3d(' + (@deltaX + @translation) + 'px,0,0)'

        e.stopPropagation()

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
        @slide @index + val, @options.speed

      e.stopPropagation()


    # Public methods

    prev: (delay) ->
      # Cancel next scheduled automatic transition, if any
      @delay = delay || 0
      clearTimeout(@interval)

      # if not at first slide
      @slide @index-1, @options.speed if @index

    next: (delay) ->
      # Cancel next scheduled automatic transition, if any
      @delay = delay || 0
      clearTimeout(@interval)

      if @index < @$slides.length - 1 # if not last slide
        @slide @index+1, @options.speed
      else # if last slide
        @slide 0, @options.speed

    stop: ->
      @delay = 0
      clearTimeout @interval

    resume: ->
      @delay = @options.auto || 0
      @_start()

    goto: (index) ->
      @slide index

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