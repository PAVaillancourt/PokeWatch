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
    
	// Pokemon bitmap single instances
	var charmander = new Ui.Bitmap({
		:rezId=>Rez.Drawables.charmander,
        :locX=>145,
        :locY=>50
    });
    
    var pikachu = new Ui.Bitmap({
    	:rezId=>Rez.Drawables.pikachu_behind,
        :locX=>25,
        :locY=>150
    });
    
 
    // Multiple instances get resource loaded
    var pikachu_name = null;
    var pikachu_lvl = null;
    var charmander_name = null;
    var charmander_lvl = null;
    var pok_hp = null;
    var health_full = null;
    var half_border_enemy = null;
    var half_border_self = null;

    // Time variables
    var timeString = "";
    var hour = null;
    var minute = null;
    
    
    function initialize() {
		WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc) {
    	canvas_w = dc.getWidth();
    	canvas_h = dc.getHeight();
    	centerpoint = [canvas_w/2, canvas_h/2];
    	    	
        setLayout(Rez.Layouts.WatchFace(dc));
        
        health_full = Ui.loadResource(Rez.Drawables.health_full);
        half_border_enemy = Ui.loadResource(Rez.Drawables.half_border_enemy);
        half_border_self = Ui.loadResource(Rez.Drawables.half_border_self);
        
        pikachu_name = "PIKACHU";
        pikachu_lvl = ":L9";
        
        charmander_name = "CHARMANDER";
        charmander_lvl = ":L12";
        pok_hp = "HP:";
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
    	hour = clockTime.hour;
	    minute = clockTime.min;
    	
    	// Clear canvas
    	dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
        dc.clear();

        // Get and show the current time
        var timeString = Lang.format("$1$:$2$", [hour, minute.format("%02d")]);

		charmander.draw(dc);
		pikachu.draw(dc);
		
		//TODO reformat x and y according to canvas_w and canvas_h
        dc.drawText(canvas_w/2, 10, Gfx.FONT_TINY, timeString, Gfx.TEXT_JUSTIFY_CENTER);
        
        // Oponent side
        dc.drawText(10, 65, Gfx.FONT_XTINY, charmander_name, Gfx.TEXT_JUSTIFY_LEFT);
        dc.drawText(45, 80, Gfx.FONT_XTINY, charmander_lvl, Gfx.TEXT_JUSTIFY_LEFT);
		dc.drawText(20, 100, Gfx.FONT_XTINY, "HP:", Gfx.TEXT_JUSTIFY_LEFT);
        dc.drawBitmap(45, 103, health_full);
        dc.drawBitmap(5, 90, half_border_enemy);
        
        // Player side
        dc.drawText(canvas_w/2-15, 130, Gfx.FONT_TINY, pikachu_name, Gfx.TEXT_JUSTIFY_LEFT);
        dc.drawText(157, 150, Gfx.FONT_XTINY, pikachu_lvl, Gfx.TEXT_JUSTIFY_LEFT);
		dc.drawText(canvas_w/2-15, 165, Gfx.FONT_XTINY, "HP:", Gfx.TEXT_JUSTIFY_LEFT);
        dc.drawBitmap(130, 168, health_full);
        dc.drawBitmap(100, 162, half_border_self);
        
        
        // Call the parent onUpdate function to redraw the layout
       // View.onUpdate(dc);
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
}
