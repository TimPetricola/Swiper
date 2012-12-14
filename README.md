# jQuery Swiper

Slideshow for mobile _à la_ Facebook.

*Plugin only tested on Chrome & Safari for iOS6.*

* *License:* MIT License
* *Author:* Tim Petricola - FrontFoot

## Usage

**HTML:**
```html
<div id="slider">
  <ul>
    <li><img src="image1.jpg" /></li>
    <li><img src="image2.jpg" /></li>
    <li><img src="image3.jpg" /></li>
  </ul>
</div>
```

**Javascript:**
```javascript
$('#slider').swiper({ auto: 1000 })
```

### Options
```javascript
{
  start: 0, // Index of the slide to show by default
  speed: 300, // Speed of slider
  auto: 0, // Delay for automatic slider (0 to disable)
  previewWidth: 0, // Size of previews on left and right of the slider
  interspace: 0, // Space between slides
  callback: function(index, $slide) {} // Runs when a new slide is shown
}
```

### Methods

#### prev
Go to previous slide.
```javascript
  $('.slider').swiper('prev')
````

#### next
Go to next slide.
```javascript
  $('.slider').swiper('next')
````

#### stop
Stop the automatic slider.
```javascript
  $('.slider').swiper('stop')
````

#### resume
Resume the automatic slider.
```javascript
  $('.slider').swiper('resume')
````

#### goto
Go to the slide at the specified index.
```javascript
  $('.slider').swiper('goto', 2) // Go to slide at index 2
````

#### position
Return the position of the current slide.
If a second argument is passed, go to this slide. (similar to goto)
```javascript
  $('.slider').swiper('position') // Return index
  $('.slider').swiper('position', 2) // Go to slide at index 2 (similar to .goto(2))
````

## Todo
* Compability tests
* Compability with Zepto
* Add keyboard support for desktop
* Tests
