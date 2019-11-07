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
	
	// Animation
	var ani_step = null;
	var is_animating = false;
	var frames_qty = 12;
	var sceneIdx = 0;
	var yOffset = 0;
	
    // Layout variables
    var canvas_h = 0;
    var canvas_w = 0;
    var centerpoint = [0,0];
    
    // Opponents
    var charmander = new pokemon("CHARMANDER",":L9",150,50);
    var squirtle = new pokemon("SQUIRTLE",":L10",160,60);
    var bulbasaur = new pokemon("BULBASAUR",":L15",160,70);
    var missingno = new pokemon("MISSINGNO",":L99",160,70);
    var opponent = null;
    
    // Pikachu
    var thunderbolts = null;
    var pikachu = new pokemon("PIKACHU", ":L9", 40, 148);

    // Common pokemon resources
    var pok_hp = null;
    var health_full = null;
    var half_border_enemy = null;
    var half_border_self = null;
    var pokeball = null;
    var pokeball_opening_shadow = null;
    
    // Text box
    var box_ball_left = null;
	var box_ball_right = null;
    var box_y_pos = 190;
    var box_x_pos = 30;

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
    
    // Steps
    var goal = 0;
    var steps = 0;
    var stepProgress = 0;
    var distance = 0;
    
    // System
    var has1hz = false;
    var deviceSettings = null;
    var is_metric = true;
    
    
    function initialize() {
		WatchFace.initialize();
		
		if( Toybox.WatchUi.WatchFace has :onPartialUpdate ) {
       		has1hz = true;
     	}
    }

    // Load your resources here
    function onLayout(dc) {
        deviceSettings = Sys.getDeviceSettings();
      	
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
        pokeball = Ui.loadResource(Rez.Drawables.pokeball);
        
        // Pokemons
        pikachu.setBitmap(Ui.loadResource(Rez.Drawables.pikachu_behind));
        pikachu.setAttack("Thunder");
        charmander.setBitmap(Ui.loadResource(Rez.Drawables.charmander));       
        squirtle.setBitmap(Ui.loadResource(Rez.Drawables.squirtle));
        bulbasaur.setBitmap(Ui.loadResource(Rez.Drawables.bulbasaur));
        missingno.setBitmap(Ui.loadResource(Rez.Drawables.missingno)); 
        
        // Animations
        thunderbolts = Ui.loadResource(Rez.Drawables.thunderbolts);
        pokeball_opening_shadow = Ui.loadResource(Rez.Drawables.pokeball_opening_shadow);
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
		// 12-hour support
		if (hour > 12 || hour == 0) {
		    if (!deviceSettings.is24Hour) {
		        if (hour == 0) {
		            hour = 12;
		        } else {
		            hour = hour - 12;
		        }
		    }
		}
	    
	    // step progress
      	var thisActivity = ActivityMonitor.getInfo();
		steps = thisActivity.steps;
		goal = thisActivity.stepGoal;
		// define our current step progress in terms of % completed
		stepProgress = (100*(steps.toFloat()/goal.toFloat())).toNumber();
		var cm_distance = thisActivity.distance;
		
		if (deviceSettings.distanceUnits == Sys.UNIT_METRIC) {
		    distance = (cm_distance).toFloat() / 100000;
		    is_metric = true;
		} else {
		    distance = (cm_distance).toFloat() / 160934;
		    is_metric = false;
		}
		
		//! TODO
		// Select opponent randomly, more steps means more chances of a higher level opponent
		if (sceneIdx == 0) {
			opponent = charmander;
		}		
    	
    	// Clear canvas
    	dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_WHITE);
        dc.clear();
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);

        // Draw "constant" components
        // Get and show the current time
        var timeString = Lang.format("$1$:$2$", [hour, minute.format("%02d")]);
        dc.drawText(canvas_w/2, 20, poke_time, timeString, Gfx.TEXT_JUSTIFY_CENTER);
        
        drawSelf(pikachu, dc);
        drawInfoBox(box_x_pos, box_y_pos, dc);
            
        // Animate
        switch (sceneIdx) {
        	case(0):
        		drawPokeBall(opponent, dc);
        		break;
        	case(1):
        		//drawOpponent(opponent, dc);
        		drawOpeningPokeBall(opponent, dc);
        		writeOpponentAppears(opponent, canvas_w, box_y_pos, dc);
        		break;
        	case(2):
        		drawOpponent(opponent, dc);
        		break;
        	case(3):
        		drawOpponent(opponent, dc);
        		writeThunder(canvas_w, box_y_pos, dc);
        		break;
        	case(4):
        		drawThunderBolts(opponent, dc, thunderbolts);
        		writeThunder(canvas_w, box_y_pos, dc);
        		break;
        	case(5):
        		dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
        		dc.clear();
        		drawSelf(pikachu, dc);
        		drawInfoBox(box_x_pos, box_y_pos, dc);
        		drawOpponent(opponent, dc);
        		writeThunder(canvas_w, box_y_pos, dc);
        		drawThunderBolts(opponent, dc, thunderbolts);
        		break;
        	case(6):
        		drawOpponent(opponent, dc);
        		writeThunder(canvas_w, box_y_pos, dc);
        		drawThunderBolts(opponent, dc, thunderbolts);
        		break;
        	case(7):
        		// Lower health bar
        	case(8):
        		if (yOffset < 100) {
        			sceneIdx--;
        			yOffset += 10;
        			dc.clear();
        			drawOpponent(opponent, dc);
        			//dc.fillRectangle(
        			drawSelf(pikachu, dc);
        			drawInfoBox(box_x_pos, box_y_pos, dc);
        		}
        		break;
        	case(9):
        		yOffset = 0;
        		writeFainted(opponent, canvas_w, box_y_pos, dc);
        	case(10):
        	case(11):
        	case(12):
        	
        	default:
        		sceneIdx = -1;
        		break;	
        }
      
        sceneIdx++;
    	if (sceneIdx >= frames_qty) {
			sceneIdx = frames_qty -1;
		}
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
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() {
	   	TIMER_1 = new Timer.Timer();
    	TIMER_1.start(method(:timerCallback), 1000, true);
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() {
    	Ui.requestUpdate();
    	
    	// Kill active timer
    	if (TIMER_1) {
    		TIMER_1.stop();
		}
    }
    
    function drawBattle(dc) {
    	
    	var step = ani_step%12;
      	var step_half = ani_step%6;
    }
    
    function writeOpponentAppears(opponent, canvas_w, box_y_pos, dc) {
    	dc.drawText(canvas_w/2, box_y_pos + 12, poke_text_small, "A wild " + opponent.getName(), Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawText(canvas_w/2, box_y_pos + 25, poke_text_small, "appeared!", Gfx.TEXT_JUSTIFY_CENTER);
    }
    
    function writeThunder(canvas_w, box_y_pos, dc) {
    	dc.drawText(canvas_w/2, box_y_pos + 12, poke_text_small, "Pikachu used", Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawText(canvas_w/2, box_y_pos + 25, poke_text_small, "Thunder!", Gfx.TEXT_JUSTIFY_CENTER);
    }
    
    function writeFainted(opponent, canvas_w, box_y_pos, dc) {
        dc.drawText(canvas_w/2, box_y_pos + 12, poke_text_small, "Enemy " + opponent.getName(), Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawText(canvas_w/2, box_y_pos + 25, poke_text_small, "fainted!", Gfx.TEXT_JUSTIFY_CENTER);
    }
    
    function drawPokeBall(opponent, dc) {
    	dc.drawBitmap(opponent.getPosX(), opponent.getPosY()+30, pokeball);
    }
    
    function drawOpeningPokeBall(opponent, dc) {
    	dc.drawBitmap(opponent.getPosX()-4, opponent.getPosY(), pokeball_opening_shadow);
    }
    
    function drawThunderBolts(opponent, dc, thunderbolts) {
    	dc.drawBitmap(opponent.getPosX() - 25, opponent.getPosY() - 20, thunderbolts);
    	var centerX = opponent.getPosX() + opponent.getBmpWidth()/2;
    	var centerY = opponent.getPosY() +opponent.getBmpHeight()/2;
    	dc.setColor(Gfx.COLOR_YELLOW, Gfx.COLOR_WHITE);
    	dc.fillCircle(centerX, centerY, opponent.getBmpWidth()/4);
    	dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
    } 
    
    function drawOpponent(opponent, dc) {
        var opponent_pos = opponent.getPosXY();
        var opponent_name_pos = [17, canvas_h/4 + 5];   
             
        // Opponent 
        dc.drawText(opponent_name_pos[0], opponent_name_pos[1], poke_text_medium, opponent.getName(), Gfx.TEXT_JUSTIFY_LEFT);
        //! TODO split ":L" and "[pokemon_lvl]" in two string, one smaller and bold, the other one normal
        dc.drawText(opponent_name_pos[0]+28, opponent_name_pos[1]+15, poke_text_small, opponent.getLvl(), Gfx.TEXT_JUSTIFY_LEFT);
		dc.drawText(opponent_name_pos[0]+3, opponent_name_pos[1]+30, poke_text_tiny_bold, "HP:", Gfx.TEXT_JUSTIFY_LEFT);
        dc.drawBitmap(opponent_name_pos[0]+23, opponent_name_pos[1]+25, health_full);
        dc.drawBitmap(opponent_name_pos[0]-12, opponent_name_pos[1]+15, half_border_enemy);
		dc.drawBitmap(opponent.getPosX(), opponent.getPosY() + yOffset, opponent.getBitmap());
		//opponent.draw(dc);
    }

    function drawSelf(pikachu, dc) {
        var self_pos = pikachu.getPosXY();
        var self_name_pos = [canvas_w/2-15, canvas_h/2 + 20];
        dc.drawText(self_name_pos[0], self_name_pos[1], poke_text_medium, pikachu.getName(), Gfx.TEXT_JUSTIFY_LEFT);
        dc.drawText(self_name_pos[0] + 50, self_name_pos[1] + 15, poke_text_small, pikachu.getLvl(), Gfx.TEXT_JUSTIFY_LEFT);
		dc.drawText(self_name_pos[0], self_name_pos[1] + 30, poke_text_tiny_bold, "HP:", Gfx.TEXT_JUSTIFY_LEFT);
        dc.drawBitmap(self_name_pos[0] + 20, self_name_pos[1] + 25, health_full);
        dc.drawBitmap(self_name_pos[0] - 10, self_name_pos[1] + 20, half_border_self);
        dc.drawBitmap(self_pos[0], self_pos[1], pikachu.getBitmap());
    }
    
    function drawInfoBox(box_x_pos, box_y_pos, dc) {
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
    }
    
    
    //function lowerOpponentHealth() {    }
    
    
    	class pokemon {
		private var bitmap = null;
		private var bitmapBW = null;
		private var name = null;
		private var lvl = null;
		private var attack = null;
		private var posX = null;
		private var posY = null;
		
		function initialize(name, lvl, posX, posY) {
			self.name = name;
			self.lvl = lvl;
			self.posX= posX;
			self.posY = posY;
		}
		
		function hashCode() {
			return name;
		}
		
		function draw(dc) {
			dc.drawBitmap(self.posX, self.posY, self.bitmap);
		}
		
		function setBitmap(bitmap) {
			self.bitmap = bitmap;
		}
		
		function setName(name) {
			self.name = name;
		}
		
		function setLvl(lvl) {
			self.lvl = lvl;
		}
		
		function setAttack(attack) {
			self.attack = attack;
		}
		
		function setPosX(posX) {
			self.posX = posX;
		}
		
		function setPosY(posY) {
			self.posY = posY;
		}
		
		function setBitmapBW(bitmapBW) {
			self.bitmapBW = bitmapBW;
		}
		
		function getPosXY() {
			return [self.posX, self.posY];
		}
		
		function getBmpHeight() {
			return self.bitmap.getHeight();
		}
		
		function getBmpWidth() {
			return self.bitmap.getWidth();
		}
		
		function getPosX() {
			return self.posX;
		}
		
		function getPosY() {
			return self.posY;
		}
		
		function getName() {
			return self.name;
		}
		
		function getLvl() {
			return self.lvl;
		}
		
		function getBitmap() {
			return self.bitmap;
		}
		
		function getBitmapBW() {
			return self.bitmapBW;
		}
		
		function getAttack() {
			return self.attack;
		}
	}
}
