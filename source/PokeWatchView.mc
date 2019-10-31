/**
 * Pierre Antoine Vaillancourt
 * (c) 2019
 */

using Toybox.WatchUi;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Application as App;
using Toybox.Timer as Timer;

// Note: dc := device context

class PokeWatchView extends Ui.WatchFace {
	
	// Globals
	var TIMER_1;
	var TIMER_TIMEOUT = 1000;
	var TIMER_STEPS = TIMER_TIMEOUT;
	
    
    // Layout variables
    var canvas_h = 0;
    var canvas_w = 0;
    var centerpoint = [0,0];
    
	// Link bitmap instance
	var charmander = new Ui.Bitmap({
		:rezId=>Rez.Drawables.charmander,
        :locX=>105,
        :locY=>90
    });
    
    var pikachu = new Ui.Bitmap({
    	:rezId=>Rez.Drawables.pikachu_behind,
        :locX=>15,
        :locY=>190
    });
    
    var timeString = "";
    
    // Button instance
    var buttonTest = new Ui.Button({
    	
    });

    // Time variables
    var hour = null;
    var minute = null;
    var day = null;
    var day_of_week = null;
    var month_str = null;
    var month = null;
    
    var linkResourcce = null;
    
    
    function initialize() {
		WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc) {
    	canvas_w = dc.getWidth();
    	canvas_h = dc.getHeight();
    	centerpoint = [canvas_w/2, canvas_h/2];
    	    	
        setLayout(Rez.Layouts.WatchFace(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    }

    // Update the view
    function onUpdate(dc) {
    	
    	// Get time and date
    	var clockTime = Sys.getClockTime();
    	var date = Time.Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
    	hour = clockTime.hour;
	    minute = clockTime.min;
        day = date.day;
        month = date.month;
        day_of_week = Time.Gregorian.info(Time.now(), Time.FORMAT_MEDIUM).day_of_week;
        month_str = Time.Gregorian.info(Time.now(), Time.FORMAT_MEDIUM).month;
    	
    	// Clear canvas
    	dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
        dc.clear();

        // Get and show the current time
        var timeString = Lang.format("$1$:$2$", [hour, minute.format("%02d")]);

		charmander.draw(dc);
		pikachu.draw(dc);
		//timeString.draw(dc);
        //dc.drawBitmap(50, 50, linkResource);
        dc.drawText(30, 50, Gfx.FONT_LARGE, timeString, Gfx.TEXT_JUSTIFY_LEFT);
        
        
        // Call the parent onUpdate function to redraw the layout
        //View.onUpdate(dc);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }
    
    // Animation loop callback
    function timerCallback() {
    	// Redraw the canvas
    	Ui.requestUpdate();
    	
    	// Timer management
    	if (TIMER_STEPS < 500) {
    		TIMER_1 = new Timer.Timer();
    		TIMER_1.start(method(:timerCallback), TIMER_STEPS, false);
		} else {
			// Stop the existing timer
			if (TIMER_1) {
				TIMER_1.stop();
			}
		}	
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() {
    	TIMER_1 = new Timer.Timer();
    	TIMER_1.start(method(:timerCallback), TIMER_STEPS, false);
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() {
    	if (TIMER_1) {
    		TIMER_1.stop();
		}
		TIMER_STEPS = TIMER_TIMEOUT;
    }
    
    // Helper function
    function rotatePoint(origin, point, angle) {
		var radians = angle * Math.PI / 180.0;
		var cos = Math.cos(radians);
		var sin = Math.sin(radians);
		var dX = point[0] - origin[0];
		var dY = point[1] - origin[1];
		
		return [ cos * dX - sin * dY + origin[0], sin * dX + cos * dY + origin[1]];
    }
}
