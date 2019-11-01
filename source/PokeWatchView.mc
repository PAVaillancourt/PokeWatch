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

    // Fonts
    //! TODO reduce font size (with BMFont)
    var poke_time = null;
    var poke_text_medium = null;
    var poke_text_small = null;
    var poke_text_tiny_bold = null;

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
        
        poke_time = Ui.loadResource(Rez.Fonts.poke_time);
        poke_text_medium = Ui.loadResource(Rez.Fonts.poke_text_medium);
        poke_text_small = Ui.loadResource(Rez.Fonts.poke_text_small);
        poke_text_tiny_bold = Ui.loadResource(Rez.Fonts.poke_text_tiny_bold);
        
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
    	dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_WHITE);
        dc.clear();
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);

        // Get and show the current time
        var timeString = Lang.format("$1$:$2$", [hour, minute.format("%02d")]);

		charmander.draw(dc);
		pikachu.draw(dc);
		
		//TODO reformat x and y according to canvas_w and canvas_h
        dc.drawText(canvas_w/2, 20, poke_time, timeString, Gfx.TEXT_JUSTIFY_CENTER);
        
        // Oponent side
        var enemy_name_pos = [15, canvas_h/4 + 5];        
        dc.drawText(enemy_name_pos[0], enemy_name_pos[1], poke_text_small, charmander_name, Gfx.TEXT_JUSTIFY_LEFT);
        //! TODO split ":L" and "[pokemon_lvl]" in two string, onme smaller and bold, the other one normal
        dc.drawText(enemy_name_pos[0]+30, enemy_name_pos[1]+15, poke_text_small, charmander_lvl, Gfx.TEXT_JUSTIFY_LEFT);
		dc.drawText(enemy_name_pos[0]+5, enemy_name_pos[1]+30, poke_text_tiny_bold, "HP:", Gfx.TEXT_JUSTIFY_LEFT);
        dc.drawBitmap(enemy_name_pos[0]+25, enemy_name_pos[1]+25, health_full);
        dc.drawBitmap(enemy_name_pos[0]-10, enemy_name_pos[1]+15, half_border_enemy);
        
        // Player side
        var self_name_pos = [canvas_w/2-15, canvas_h/2 + 20];
        dc.drawText(self_name_pos[0], self_name_pos[1], poke_text_medium, pikachu_name, Gfx.TEXT_JUSTIFY_LEFT);
        dc.drawText(self_name_pos[0] + 50, self_name_pos[1] + 15, poke_text_small, pikachu_lvl, Gfx.TEXT_JUSTIFY_LEFT);
		dc.drawText(self_name_pos[0], self_name_pos[1] + 30, poke_text_tiny_bold, "HP:", Gfx.TEXT_JUSTIFY_LEFT);
        dc.drawBitmap(self_name_pos[0] + 20, self_name_pos[1] + 25, health_full);
        dc.drawBitmap(self_name_pos[0] - 10, self_name_pos[1] + 20, half_border_self);
        
        
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
