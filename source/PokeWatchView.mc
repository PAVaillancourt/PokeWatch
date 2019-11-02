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
    
    // Pikachu
    var pikachu = null;
    var pikachu_name = null;
    var pikachu_lvl = null;
    var thunderbolts = null;
    
    // Charmander
    var charmander = null;
    var charmander_name = null;
    var charmander_lvl = null;

    // Squirtle
    var squirtle = null;
    var squirtle_name = null;
    var squirtle_lvl = null;

    // Bulbasaur
    var bulbasaur = null;
    var bulbasaur_name = null;
    var bulbasaur_lvl = null;

    // Common pokemon resources
    var pok_hp = null;
    var health_full = null;
    var half_border_enemy = null;
    var half_border_self = null;
    
    // Text box
    var box_ball_left = null;
	var box_ball_right = null;

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
        
        // Fonts
        poke_time = Ui.loadResource(Rez.Fonts.poke_time);
        poke_text_medium = Ui.loadResource(Rez.Fonts.poke_text_medium);
        poke_text_small = Ui.loadResource(Rez.Fonts.poke_text_small);
        poke_text_tiny_bold = Ui.loadResource(Rez.Fonts.poke_text_tiny_bold);
        box_ball_left = Ui.loadResource(Rez.Drawables.box_ball);
        box_ball_right = Ui.loadResource(Rez.Drawables.box_ball);
        
        // GUI
        health_full = Ui.loadResource(Rez.Drawables.health_full);
        half_border_enemy = Ui.loadResource(Rez.Drawables.half_border_enemy);
        half_border_self = Ui.loadResource(Rez.Drawables.half_border_self);
        pok_hp = "HP:";
        
        // Pokemons
        pikachu = Ui.loadResource(Rez.Drawables.pikachu_behind);
        pikachu_name = "PIKACHU";
        pikachu_lvl = ":L9";
        
        charmander = Ui.loadResource(Rez.Drawables.charmander);
        charmander_name = "CHARMANDER";
        charmander_lvl = ":L12";
        
        squirtle = Ui.loadResource(Rez.Drawables.squirtle);
        squirtle_name = "SQUIRTLE";
        squirtle_lvl = ":L11";
        
        bulbasaur = Ui.loadResource(Rez.Drawables.bulbasaur);
        bulbasaur_name = "BULBASAUR";
        bulbasaur_lvl = ":L15";
        
        // Animations
        thunderbolts = Ui.loadResource(Rez.Drawables.thunderbolts);
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

		
		//TODO reformat x and y according to canvas_w and canvas_h
        dc.drawText(canvas_w/2, 20, poke_time, timeString, Gfx.TEXT_JUSTIFY_CENTER);
        
	
		var opponent_pos = createOpponent(bulbasaur, bulbasaur_name, bulbasaur_lvl, dc);
        
        // Player side
        var self_pos = [40, 150];
        var self_name_pos = [canvas_w/2-15, canvas_h/2 + 20];
        dc.drawText(self_name_pos[0], self_name_pos[1], poke_text_medium, pikachu_name, Gfx.TEXT_JUSTIFY_LEFT);
        dc.drawText(self_name_pos[0] + 50, self_name_pos[1] + 15, poke_text_small, pikachu_lvl, Gfx.TEXT_JUSTIFY_LEFT);
		dc.drawText(self_name_pos[0], self_name_pos[1] + 30, poke_text_tiny_bold, "HP:", Gfx.TEXT_JUSTIFY_LEFT);
        dc.drawBitmap(self_name_pos[0] + 20, self_name_pos[1] + 25, health_full);
        dc.drawBitmap(self_name_pos[0] - 10, self_name_pos[1] + 20, half_border_self);
        dc.drawBitmap(self_pos[0], self_pos[1], pikachu);
        
        
        // Info box
        var box_y_pos = 190;
        var box_x_pos = 30;

        dc.setPenWidth(2);
        dc.drawArc(canvas_w/2, canvas_h/2, canvas_w/2 - 4, Gfx.ARC_COUNTER_CLOCKWISE, 225, 315); 
        dc.drawLine(box_x_pos + box_ball_left.getWidth(), box_y_pos + box_ball_left.getHeight()/2+1,
        			 canvas_w - box_x_pos - box_ball_right.getWidth(), box_y_pos + box_ball_right.getHeight()/2+1);
        dc.setPenWidth(1);
		dc.drawArc(canvas_w/2, canvas_h/2, canvas_w/2 - 6, Gfx.ARC_COUNTER_CLOCKWISE, 225, 315); 
        dc.drawLine(box_x_pos + box_ball_left.getWidth()-1, box_y_pos + box_ball_left.getHeight()/2-2,
        			 canvas_w - box_x_pos - box_ball_right.getWidth()+1, box_y_pos + box_ball_right.getHeight()/2-2);
        dc.drawBitmap(box_x_pos, box_y_pos,box_ball_left);
        dc.drawBitmap(canvas_w - box_x_pos - box_ball_right.getWidth(), box_y_pos, box_ball_right);
        
        // Info box text
		useThunder(canvas_w, box_y_pos, dc);
        
        drawThunderBolts(opponent_pos[0], opponent_pos[1], charmander, dc, thunderbolts);
        
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
    
    function useThunder(canvas_w, box_y_pos, dc) {
    	dc.drawText(canvas_w/2, box_y_pos + 12, poke_text_small, "Pikachu used", Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawText(canvas_w/2, box_y_pos + 25, poke_text_small, "Thunder!", Gfx.TEXT_JUSTIFY_CENTER);
    }
    
    function drawThunderBolts(opponentX, opponentY, opponent, dc, thunderbolts) {
    	dc.drawBitmap(opponentX - 25, opponentY - 20, thunderbolts);
    	var centerX = opponentX + opponent.getWidth()/2;
    	var centerY = opponentY +opponent.getHeight()/2;
    	dc.setColor(Gfx.COLOR_YELLOW, Gfx.COLOR_WHITE);
    	dc.fillCircle(centerX, centerY, opponent.getWidth()/4);
    	dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
    } 
    
    function createOpponent(opponent, opponent_name, opponent_lvl, dc) {
        // Oponent side
        var opponent_pos = [150, 50];
        var enemy_name_pos = [17, canvas_h/4 + 5];        
        dc.drawText(enemy_name_pos[0], enemy_name_pos[1], poke_text_medium, opponent_name, Gfx.TEXT_JUSTIFY_LEFT);
        //! TODO split ":L" and "[pokemon_lvl]" in two string, onme smaller and bold, the other one normal
        dc.drawText(enemy_name_pos[0]+28, enemy_name_pos[1]+15, poke_text_small, opponent_lvl, Gfx.TEXT_JUSTIFY_LEFT);
		dc.drawText(enemy_name_pos[0]+3, enemy_name_pos[1]+30, poke_text_tiny_bold, "HP:", Gfx.TEXT_JUSTIFY_LEFT);
        dc.drawBitmap(enemy_name_pos[0]+23, enemy_name_pos[1]+25, health_full);
        dc.drawBitmap(enemy_name_pos[0]-12, enemy_name_pos[1]+15, half_border_enemy);
		dc.drawBitmap(opponent_pos[0], opponent_pos[1], opponent);
		return opponent_pos;
    }
    
    //function lowerOpponentHealth() {    }
}
