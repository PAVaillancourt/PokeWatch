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
    var pikachu = new pokemon("PIKACHU", ":L9", 40, 148);
    var thunderbolts = null;
    
    // Opponents
    var charmander = new pokemon("CHARMANDER", ":L9", 150, 50);
    var squirtle = new pokemon("SQUIRTLE", ":L10", 160, 50);
    var bulbasaur = new pokemon("BULBASAUR", ":L15", 160, 60);
    var missingno = new pokemon("MISSINGNO", ":L99", 160, 70);
    var opponent = null;

    // Common pokemon resources
    var pok_hp = null;
    var health_full = null;
    var half_border_enemy = null;
    var half_border_self = null;
    var pokeball = null;
    
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
        dc.drawText(canvas_w/2, 20, poke_time, timeString, Gfx.TEXT_JUSTIFY_CENTER);
        
		opponent = missingno;
		//drawOpponent(opponent, dc);		
        dc.drawBitmap(opponent.getPosX(), opponent.getPosY()+30, pokeball);
		drawSelf(pikachu, dc);

		drawInfoBox(dc);
        
        
        // Info box text
		//useThunder(canvas_w, box_y_pos, dc);
        
        //drawThunderBolts(charmander, dc, thunderbolts);
        
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
    
    function useThunder(canvas_w, box_y_pos, dc) {
    	dc.drawText(canvas_w/2, box_y_pos + 12, poke_text_small, "Pikachu used", Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawText(canvas_w/2, box_y_pos + 25, poke_text_small, "Thunder!", Gfx.TEXT_JUSTIFY_CENTER);
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
		dc.drawBitmap(opponent.getPosX(), opponent.getPosY(), opponent.getBitmap());
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
    
    function drawInfoBox(dc) {
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
    }
    
    
    //function lowerOpponentHealth() {    }
    
    
    	class pokemon extends Ui.Bitmap {
		private var bitmap = null;
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
			return posY;
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
		
		function getAttack() {
			return self.attack;
		}
	}
}
