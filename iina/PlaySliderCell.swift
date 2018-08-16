//
//  PlaySlider.swift
//  iina
//
//  Created by lhc on 25/7/16.
//  Copyright © 2016 lhc. All rights reserved.
//

import Cocoa

// These colors are for 10.13- only
@available(macOS, obsoleted: 10.14)
fileprivate extension NSColor {
  static let darkKnobColor = NSColor(red: 1, green: 1, blue: 1, alpha: 0.5)
  static let lightKnobColor = NSColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1)
  static let darkBarColorLeft = NSColor(white: 1, alpha: 0.3)
  static let darkBarColorRight = NSColor(white: 1, alpha: 0.1)
  static let lightBarColorLeft = NSColor(red: 0.239, green: 0.569, blue: 0.969, alpha: 1)
  static let lightBarColorRight = NSColor(white: 0.5, alpha: 0.5)
  static let lightChapterStrokeColor = NSColor(white: 0.4, alpha: 1)
  static let darkChapterStrokeColor = NSColor(white: 0.2, alpha: 1)
}

class PlaySliderCell: NSSliderCell {

  lazy var playerCore: PlayerCore = {
    return (self.controlView!.window!.windowController as! MainWindowController).player
  }()

  override var knobThickness: CGFloat {
    return knobWidth
  }

  let knobWidth: CGFloat = 3
  let knobHeight: CGFloat = 15
  let knobRadius: CGFloat = 1
  let barRadius: CGFloat = 1.5

  var isInDarkTheme: Bool = true {
    didSet {
      if #available(macOS 10.14, *) {} else {
        self.knobColor = isInDarkTheme ? .darkKnobColor : .lightKnobColor
        self.knobActiveColor = isInDarkTheme ? .darkKnobColor : .lightKnobColor
        self.barColorLeft = isInDarkTheme ? .darkBarColorLeft : .lightBarColorLeft
        self.barColorRight = isInDarkTheme ? .darkBarColorRight : .lightBarColorRight
        self.chapterStrokeColor = isInDarkTheme ? .darkChapterStrokeColor : .lightChapterStrokeColor
      }
    }
  }

  private var knobColor: NSColor = {
    if #available(macOS 10.14, *) {
      return NSColor(named: .mainSliderKnob)!
    } else {
      return .darkKnobColor
    }
  }()
  private var knobActiveColor: NSColor = {
    if #available(macOS 10.14, *) {
      return NSColor(named: .mainSliderKnobActive)!
    } else {
      return .darkKnobColor
    }
  }()
  private var barColorLeft: NSColor = {
    if #available(macOS 10.14, *) {
      return NSColor(named: .mainSliderBarLeft)!
    } else {
      return .darkBarColorLeft
    }
  }()
  private var barColorRight: NSColor = {
    if #available(macOS 10.14, *) {
      return NSColor(named: .mainSliderBarRight)!
    } else {
      return .darkBarColorRight
    }
  }()
  private var chapterStrokeColor: NSColor = {
    if #available(macOS 10.14, *) {
      return NSColor(named: .mainSliderBarChapterStroke)!
    } else {
      return .darkChapterStrokeColor
    }
  }()

  var drawChapters = Preference.bool(for: .showChapterPos)

  var isPausedBeforeSeeking = false

  override func awakeFromNib() {
    minValue = 0
    maxValue = 100
  }

  override func drawKnob(_ knobRect: NSRect) {
    // Round the X position for cleaner drawing
    let rect = NSMakeRect(round(knobRect.origin.x),
                          knobRect.origin.y + 0.5 * (knobRect.height - knobHeight),
                          knobRect.width,
                          knobHeight)
    let isLightTheme = !controlView!.window!.effectiveAppearance.isDark

    if #available(macOS 10.14, *), isLightTheme {
      NSGraphicsContext.saveGraphicsState()
      let shadow = NSShadow()
      shadow.shadowBlurRadius = 1
      shadow.shadowColor = .controlShadowColor
      shadow.shadowOffset = NSSize(width: 0, height: -0.5)
      shadow.set()
    }

    let path = NSBezierPath(roundedRect: rect, xRadius: knobRadius, yRadius: knobRadius)
    (isHighlighted ? knobActiveColor : knobColor).setFill()
    path.fill()

    if #available(macOS 10.14, *), isLightTheme {
      path.lineWidth = 0.4
      NSColor.controlShadowColor.setStroke()
      path.stroke()
      NSGraphicsContext.restoreGraphicsState()
    }
  }

  override func knobRect(flipped: Bool) -> NSRect {
    let slider = self.controlView as! NSSlider
    let bounds = super.barRect(flipped: flipped)
    let percentage = slider.doubleValue / (slider.maxValue - slider.minValue)
    let pos = min(CGFloat(percentage) * bounds.width, bounds.width - 1);
    let rect = super.knobRect(flipped: flipped)
    let flippedMultiplier = flipped ? CGFloat(-1) : CGFloat(1)
    return NSMakeRect(pos - flippedMultiplier * 0.5 * knobWidth, rect.origin.y, knobWidth, rect.height)
  }

  override func drawBar(inside rect: NSRect, flipped: Bool) {
    let info = playerCore.info
    
    let slider = self.controlView as! NSSlider
    
    /// The position of the knob, rounded for cleaner drawing
    let knobPos : CGFloat = round(knobRect(flipped: flipped).origin.x);
    
    /// How far progressed the current video is, used for drawing the bar background
    var progress : CGFloat = 0;
    
    if info.isNetworkResource,
      info.cacheTime != 0,
      let duration = info.videoDuration,
      duration.second != 0 {
      let pos = Double(info.cacheTime) / Double(duration.second) * 100
      progress = round(rect.width * CGFloat(pos / (slider.maxValue - slider.minValue))) + 2;
    } else {
      progress = knobPos;
    }
    
    let rect = NSMakeRect(rect.origin.x, rect.origin.y + 1, rect.width, rect.height - 2)
    let path = NSBezierPath(roundedRect: rect, xRadius: barRadius, yRadius: barRadius)

    // draw left
    let pathLeftRect : NSRect = NSMakeRect(rect.origin.x, rect.origin.y, progress, rect.height)
    NSBezierPath(rect: pathLeftRect).addClip();

    if #available(macOS 10.14, *), !controlView!.window!.effectiveAppearance.isDark {
      // Draw knob shadow in 10.14+ light theme
    } else {
      // Clip 1px around the knob
      path.append(NSBezierPath(rect: NSRect(x: knobPos - 1, y: rect.origin.y, width: knobWidth + 2, height: rect.height)).reversed);
    }
    
    barColorLeft.setFill()
    path.fill()
    NSGraphicsContext.restoreGraphicsState()

    // draw right
    NSGraphicsContext.saveGraphicsState()
    let pathRight = NSMakeRect(rect.origin.x + progress, rect.origin.y, rect.width - progress, rect.height)
    NSBezierPath(rect: pathRight).setClip()
    barColorRight.setFill()
    path.fill()
    NSGraphicsContext.restoreGraphicsState()

    // draw chapters
    NSGraphicsContext.saveGraphicsState()
    if drawChapters {
      if let totalSec = info.videoDuration?.second {
        chapterStrokeColor.setStroke()
        var chapters = info.chapters
        if chapters.count > 0 {
          chapters.remove(at: 0)
          chapters.forEach { chapt in
            let chapPos = CGFloat(chapt.time.second) / CGFloat(totalSec) * rect.width
            let linePath = NSBezierPath()
            linePath.move(to: NSPoint(x: chapPos, y: rect.origin.y))
            linePath.line(to: NSPoint(x: chapPos, y: rect.origin.y + rect.height))
            linePath.stroke()
          }
        }
      }
    }
    NSGraphicsContext.restoreGraphicsState()
  }

  override func barRect(flipped: Bool) -> NSRect {
    let rect = super.barRect(flipped: flipped)
    return NSMakeRect(0, rect.origin.y, rect.width + rect.origin.x * 2, rect.height)
  }


  override func startTracking(at startPoint: NSPoint, in controlView: NSView) -> Bool {
    isPausedBeforeSeeking = playerCore.info.isPaused
    let result = super.startTracking(at: startPoint, in: controlView)
    if result {
      playerCore.togglePause(true)
      playerCore.mainWindow.thumbnailPeekView.isHidden = true
    }
    return result
  }

  override func stopTracking(last lastPoint: NSPoint, current stopPoint: NSPoint, in controlView: NSView, mouseIsUp flag: Bool) {
    if !isPausedBeforeSeeking {
      playerCore.togglePause(false)
    }
    super.stopTracking(last: lastPoint, current: stopPoint, in: controlView, mouseIsUp: flag)
  }

}
