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
using Toybox.Math;

// Note: dc := device context

class PokeWatchView extends Ui.WatchFace {


	// Globals
	var TIMER_1;
	
	// Animation
	var ani_step = null;
	var is_animating = false;
	var frames_qty = 12;
	var sceneIdx = 0;
	var yOffset = 0;
	var timerDelay = 500;
	var flashesRemaining = 8;
	var sceneRepeat1 = 0;
	var sceneRepeat2 = 0;
	
    // Layout variables
    var canvas_h = 0;
    var canvas_w = 0;
    var centerpoint = [0,0];
    
    // Opponents
    var charmander = new pokemon("CHARMANDER",":L9",150,50);
    var squirtle = new pokemon("SQUIRTLE",":L23",160,60);
    var bulbasaur = new pokemon("BULBASAUR",":L46",160,70);
    var missingno = new pokemon("MISSINGNO",":L99",160,70);
    var opponent = null;
    var opponentList = null;
    
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
    var health_remaining = 1;
    
    // Text box
    var box_ball_left = null;
	var box_ball_right = null;
    var box_y_pos = 190;
    var box_x_pos = 30;

    // Fonts
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
    var deviceSettings = null;
    
    function initialize() {
		WatchFace.initialize();
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
        opponentList = [charmander, bulbasaur, squirtle, missingno];
        
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
    	
    	// Clear canvas
    	dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_WHITE);
        dc.clear();
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);

        // Draw "constant" components
        // Get and show the current time
		drawTime(dc);        
        drawSelf(pikachu, dc);
        drawInfoBox(box_x_pos, box_y_pos, dc);
        
		// Select opponent according to step progress
		if (sceneIdx == 0) {
			opponent = selectOpponent(opponentList);
		}		

        // No animation in low power mode
        if (!is_animating) {
        	drawPokeBall(opponent, dc);
        	return;
        }

		// Start animation sequence
        // System updates every second via requestUpdate, notwithstanding timers
        // Animate
        switch (sceneIdx) {
        	case(0):
        		// Waiting screen
        		//System.println("Case 0");
        		sceneRepeat2 = 3;
        		drawPokeBall(opponent, dc);
        		break;
        	case(1):
        		// A wild pokemon appears!
        		//System.println("Case 1");
        		sceneRepeat1 = 2;
        		drawOpponent(opponent, dc);
        		writeOpponentAppears(opponent, canvas_w, box_y_pos, dc);
        		if (sceneRepeat2 > 0 ) {
	        		sceneRepeat2--;
	        		sceneIdx--;
        		}
        		break;
        	case(2):
        		// Opponent visible
        		//System.println("Case 2");
        		sceneRepeat2 = 3;
    			drawOpponent(opponent, dc);
        		if (sceneRepeat1 > 0) {
        			sceneRepeat1--;
        			sceneIdx--;
        		}
    			break;
        	case(3):
        		// Pikachu uses thunder!
        		//System.println("Case 3");
        		drawOpponent(opponent, dc);
        		writeThunder(canvas_w, box_y_pos, dc);
        		if (sceneRepeat2 > 0) {
	        		sceneRepeat2--;
	        		sceneIdx--;
        		}
        		break;
        	case(4):
        		// Thunderbolts visible
        		//System.println("Case 4");
        		drawOpponent(opponent, dc);
        		drawThunderBolts(opponent, dc, thunderbolts);
        		writeThunder(canvas_w, box_y_pos, dc);
        		break;
        	case(5):
        		// Thunderbolts visible, black bckgrnd
        		//System.println("Case 5");
        		dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
        		dc.clear();
        		drawTime(dc);
        		drawSelf(pikachu, dc);
        		drawInfoBox(box_x_pos, box_y_pos, dc);
        		drawOpponent(opponent, dc);
        		writeThunder(canvas_w, box_y_pos, dc);
        		drawThunderBolts(opponent, dc, thunderbolts);
        		break;
        	case(6):
        		// Thunderbolts visible
        		//System.println("Case 6");
        		drawOpponent(opponent, dc);
        		writeThunder(canvas_w, box_y_pos, dc);
        		drawThunderBolts(opponent, dc, thunderbolts);
        		break;   		
        	case(7):
        	case(8):
        		// Opponent loses health
        		//System.println("Case 8");
    			drawOpponent(opponent, dc);
        		if (health_remaining > 0.1) { // Can<t be 0 since 0.0000000 != 0 ...
        			sceneIdx--;
        			health_remaining -= 0.25;
        			lowerOpponentHealth(health_remaining, dc);
        		}
        		break;
        	case(9):
        		// Opponent faints (slides down)
        		//System.println("Case 9");
        		if (yOffset < 100) {
        			sceneIdx--;
        			yOffset += 20;
        			//dc.clear();
        			drawOpponent(opponent, dc);
        			lowerOpponentHealth(health_remaining, dc);
        			dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_WHITE);
        			dc.fillRectangle(opponent.getPosX(), opponent.getPosY()+opponent.getBmpHeight()+20, 70, 80);
        			dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
        			drawSelf(pikachu, dc);
        			drawInfoBox(box_x_pos, box_y_pos, dc);
        		}
        		sceneRepeat2 = 3;
        		sceneRepeat1 = 3;
        		break;
        	case(10):
        		// Opponent fainted!
        		//System.println("Case 10");
        		yOffset = 0;
        		health_remaining = 1;
        		if (sceneRepeat2 > 0) {
        			sceneRepeat2--;
        			sceneIdx--;
	        		writeFainted(opponent, canvas_w, box_y_pos, dc);
        		}
        		break;
        	case(11):
        		// Victory!
        		//System.println("Case 11");
        		if (sceneRepeat1 > 0) {
        			sceneRepeat1--;
        			sceneIdx--;
	        		writeVictory(dc);
	        		break;
        		}
        		is_animating = false;
        		break;
        	default:
        		//System.println("Case Default");
        		sceneIdx = -1;
        		break;	
        }
      
      	//System.println("End");
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
    	
    	/**
    	Since the system updates the screen every second, to keep some scenes 
    	longer, we have to use a sceneRepeat variable. On the contrary, for scenes
    	that have to repeat in a short interval, we use the timer.
    	*/
    	TIMER_1.stop();
    	TIMER_1 = new Timer.Timer();
    	TIMER_1.start(method(:timerCallback), timerDelay, false);
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() {
    	sceneIdx = 0;
    	is_animating = true;
    	timerDelay = 500;
	   	TIMER_1 = new Timer.Timer();
    	TIMER_1.start(method(:timerCallback), timerDelay, false);
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() {
    	sceneIdx = 0;
    	is_animating = false;
    	timerDelay = 1000;
    	Ui.requestUpdate();
    	
    	// Kill active timer
    	if (TIMER_1) {
    		TIMER_1.stop();
		}
    }
    
    function drawTime(dc) {
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
		
		var timeString = Lang.format("$1$:$2$", [hour, minute.format("%02d")]);
        dc.drawText(canvas_w/2, 20, poke_time, timeString, Gfx.TEXT_JUSTIFY_CENTER);
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
    
    function writeVictory(dc) {
    	dc.drawText(canvas_w/2, box_y_pos + 12, poke_text_small, "Victory!", Gfx.TEXT_JUSTIFY_CENTER);
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
        dc.drawBitmap(opponent_name_pos[0]+27, opponent_name_pos[1]+32, health_full);
        dc.drawBitmap(opponent_name_pos[0]-12, opponent_name_pos[1]+15, half_border_enemy);
		dc.drawBitmap(opponent_pos[0], opponent_pos[1] + yOffset, opponent.getBitmap());
    }

    function drawSelf(pikachu, dc) {
        var self_pos = pikachu.getPosXY();
        var self_name_pos = [canvas_w/2-15, canvas_h/2 + 20];
        dc.drawText(self_name_pos[0], self_name_pos[1], poke_text_medium, pikachu.getName(), Gfx.TEXT_JUSTIFY_LEFT);
        dc.drawText(self_name_pos[0] + 50, self_name_pos[1] + 15, poke_text_small, pikachu.getLvl(), Gfx.TEXT_JUSTIFY_LEFT);
		dc.drawText(self_name_pos[0], self_name_pos[1] + 30, poke_text_tiny_bold, "HP:", Gfx.TEXT_JUSTIFY_LEFT);
        dc.drawBitmap(self_name_pos[0] + 25, self_name_pos[1] + 32, health_full);
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
        dc.drawBitmap(box_x_pos, box_y_pos, box_ball_left);
        dc.drawBitmap(canvas_w - box_x_pos - box_ball_right.getWidth(), box_y_pos, box_ball_right);
    }
    
    function lowerOpponentHealth(health_remaining, dc) {
        var opponent_name_pos = [17, canvas_h/4 + 5];
        var health_bar_width = health_full.getWidth() - 6; // Width of green part
        var hbw_adjusted = health_bar_width * health_remaining;
        // Adjusting for rounding
        if (health_remaining <= 0.1) {
        	hbw_adjusted = -3;
    	}
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_WHITE);
    	dc.fillRectangle(
    		opponent_name_pos[0] + 32 + hbw_adjusted,
    		opponent_name_pos[1] + 34,
    		Math.round(health_bar_width - hbw_adjusted),
    		2
    		);
    }
    
    function selectOpponent(opponentList) {
    	// step progress
      	var thisActivity = ActivityMonitor.getInfo();
		steps = 7500;//thisActivity.steps;
		goal = thisActivity.stepGoal;
		// define our current step progress
		stepProgress = ((steps.toFloat()/goal.toFloat())*4).toNumber();
		stepProgress = (stepProgress) >= 4 ? 3 : stepProgress;
		
		return opponentList[stepProgress];
    }
    
	class pokemon {
		private var bitmap = null;
		private var bitmapBW = null;
		private var name = null;
		private var lvl = null;
		private var attack = null;
		private var posX = null;
		private var posY = null;
		private var offsetY = null;
		private var offsetX = null;
		
		function initialize(name, lvl, posX, posY) {
			self.name = name;
			self.lvl = lvl;
			self.posX= posX;
			self.posY = posY;
			self.offsetX = 0;
			self.offsetY = 0;
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
		
		function setOffsetY(offsetY) {
			self.offsetY = offsetY;
		}

		function setOffsetX(offsetX) {
			self.offsetX = offsetX;
		}
		
		function setBitmapBW(bitmapBW) {
			self.bitmapBW = bitmapBW;
		}
		
		function getOffsetX() {
			return self.offsetX;
		}

		function getOffsetY() {
			return self.offsetY;
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
		
		// TODO
		function fadeDown(offsetY) {
			return self.offsetY;
		}
		
		// TODO
		function fadeIn(offsetX) {
			return self.offsetX;
		}
	}
}
