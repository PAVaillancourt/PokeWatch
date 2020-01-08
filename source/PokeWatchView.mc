/**
 * Pierre Antoine Vaillancourt
 * (c) 2019
 */

using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Application as App;
using Toybox.Timer as Timer;
using Toybox.Math;

class PokeWatchView extends Ui.WatchFace {
	
	// Animation
	var TIMER_1;
	var animationStep = null;
	var isAnimating = false;
	var sceneIdx = 0;
	var yOffset = 0;
	var timerDelay = 500;
	var flashesRemaining = 8;
	var sceneRepeat1 = 0;
	var sceneRepeat2 = 0;
	
    // Layout variables
    var canvasH = 0;
    var canvasW = 0;
    var centerpoint = [0,0];
    var arcStart = 0;
    var arcEnd = 0;
    
    // Opponents
	var charmander = null;
	var squirtle = null;
	var bulbasaur = null;
	var ivysaur = null;
	var wartortle = null;
	var charizard = null;
	var blastoise = null;
	var missingno = null;
    var opponent = null;
    var opponentList = null;
    
    // Pikachu
    var thunderbolts = null;
    var pikachu = null;

    // Common pokemon resources
    var healthEmpty = null;
    var halfBorderEnemy = null;
    var halfBorderSelf = null;
    var pokeball = null;
    var pokeballOpening = null;
    var healthRemaining = 1;
    
    // Text box
    var boxBallLeft = null;
	var boxBallRight = null;
    var boxY = null;
    var boxX = null;

    // Fonts
    var pokeTime = null;
    var pokeTextMedium = null;
    var pokeTextSmall = null;
    var pokeTextTinyBold = null;

    // Time variables
    var timeString = "";
    var hour = null;
    var minute = null;
    
    // Steps
    var goal = 0;
    var steps = 0;
    var stepProgress = 0;
    var distance = 0;
    var pokemonPos = null;
    
    // System
    var deviceSettings = null;
    
    function initialize() {
		WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc) {
        deviceSettings = Sys.getDeviceSettings();
      	
    	canvasW = dc.getWidth();
    	canvasH = dc.getHeight();
    	centerpoint = [canvasW/2, canvasH/2];
    	arcStart = canvasW > 240 ? 224 : 225;
    	arcEnd = canvasW > 240 ? 316 : 315;
    	    	
        setLayout(Rez.Layouts.WatchFace(dc));
        
        // Fonts
        pokeTime = Ui.loadResource(Rez.Fonts.pokeTime);
        pokeTextMedium = Ui.loadResource(Rez.Fonts.pokeTextMedium);
        pokeTextSmall = Ui.loadResource(Rez.Fonts.pokeTextSmall);
        pokeTextTinyBold = Ui.loadResource(Rez.Fonts.pokeTextTinyBold);
        boxBallLeft = Ui.loadResource(Rez.Drawables.box_ball);
        boxBallRight = Ui.loadResource(Rez.Drawables.box_ball);
        
        // GUI
        boxY = 19*canvasH/24;
    	boxX = 3*canvasW/24;
        healthEmpty = Ui.loadResource(Rez.Drawables.healthEmpty);
        halfBorderEnemy = Ui.loadResource(Rez.Drawables.halfBorderEnemy);
        halfBorderSelf = Ui.loadResource(Rez.Drawables.halfBorderSelf);
        pokeball = Ui.loadResource(Rez.Drawables.pokeball);
        
        // Precalcs
        var posX160 = 160 * canvasW / 240;
        var posY70 = 70 * canvasH / 240;
        
        // Pokemons
        charmander = new pokemon("Charmander",":L4",180*canvasW/240,75*canvasH/240);
	    squirtle = new pokemon("Squirtle",":L8",170*canvasW/240,75*canvasH/240);
	    bulbasaur = new pokemon("Bulbasaur",":L15",170,posY70);
	    ivysaur = new pokemon("Ivysaur",":L16",posX160,posY70);
	    wartortle = new pokemon("Wartortle",":L23",posX160,posY70);
	    charizard = new pokemon("Charizard",":L42",posX160,posY70);
	    blastoise = new pokemon("Blastoise",":L69",posX160,posY70);
	    missingno = new pokemon("Missigno",":L99",posX160,posY70);
	    pikachu = new pokemon("PIKACHU", ":L", 40*canvasW/240,148*canvasH/240);
        pikachu.setBitmap(Ui.loadResource(Rez.Drawables.pikachu_behind));
        pikachu.setAttack("Thunder");
        charmander.setBitmap(Ui.loadResource(Rez.Drawables.charmander));       
        squirtle.setBitmap(Ui.loadResource(Rez.Drawables.squirtle));
        bulbasaur.setBitmap(Ui.loadResource(Rez.Drawables.bulbasaur));
        ivysaur.setBitmap(Ui.loadResource(Rez.Drawables.ivysaur));
        wartortle.setBitmap(Ui.loadResource(Rez.Drawables.wartortle));
        charizard.setBitmap(Ui.loadResource(Rez.Drawables.charizard));
        blastoise.setBitmap(Ui.loadResource(Rez.Drawables.blastoise));
        missingno.setBitmap(Ui.loadResource(Rez.Drawables.missingno)); 
        opponentList = [[charmander, bulbasaur, squirtle], [ivysaur, wartortle], [charizard, blastoise], [missingno]];
        
        // Animations
        thunderbolts = Ui.loadResource(Rez.Drawables.thunderbolts);
        pokeballOpening = Ui.loadResource(Rez.Drawables.pokeballOpening);
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
		drawTime(dc);
		var pikachuLvl = getStepProgress(99) > 100 ? 99 : getStepProgress(99);
		pikachuLvl = pikachuLvl < 4 ? 4 : pikachuLvl;
		pikachu.setLvl(":L" + (pikachuLvl.toString()));
        drawSelf(pikachu, dc);
        drawInfoBox(boxX, boxY, dc);
 
		// Select opponent according to step progress
		if (sceneIdx == 0) {
			opponent = selectOpponent(opponentList);
		}		

        // No animation in low power mode
        if (!isAnimating) {
        	drawPokeBall(opponent, dc);
        	return;
        }

        /**
    	Since the system updates the screen every second, to keep some scenes 
    	longer, we have to use sceneRepeat variables.
    	*/
		// Start animation sequence
        // Animate
        switch (sceneIdx) {
        	case(0):
        		// Waiting screen
        		//System.println("Case 0");
        		drawPokeBall(opponent, dc);
        		// Prepare case 1
        		sceneRepeat2 = 2;
        		break;
        	case(1):
        		// A wild pokemon appears!
        		//System.println("Case 1");
        		drawOpponent(opponent, dc);
        		drawOpeningPokeBall(opponent, dc);
        		writeOpponentAppears(opponent, canvasW, boxY, dc);
        		if (sceneRepeat2 > 0 ) {
	        		sceneRepeat2--;
	        		sceneIdx--;
        		}
				// Prepare case 2
        		sceneRepeat1 = 2;
        		break;
        	case(2):
        		// Opponent visible
        		//System.println("Case 2");
    			drawOpponent(opponent, dc);
        		if (sceneRepeat1 > 0) {
        			sceneRepeat1--;
        			sceneIdx--;
        		}
				// Prepare case 3
        		sceneRepeat2 = 3;
    			break;
        	case(3):
        		// Pikachu uses thunder!
        		//System.println("Case 3");
        		drawOpponent(opponent, dc);
        		writeThunder(canvasW, boxY, dc);
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
        		writeThunder(canvasW, boxY, dc);
        		break;
        	case(5):
        		// Thunderbolts visible, black bckgrnd
        		//System.println("Case 5");
        		dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
        		dc.clear();
        		drawTime(dc);
        		drawSelf(pikachu, dc);
        		drawInfoBox(boxX, boxY, dc);
        		drawOpponent(opponent, dc);
        		writeThunder(canvasW, boxY, dc);
        		drawThunderBolts(opponent, dc, thunderbolts);
        		break;
        	case(6):
        		// Thunderbolts visible
        		//System.println("Case 6");
        		drawOpponent(opponent, dc);
        		writeThunder(canvasW, boxY, dc);
        		drawThunderBolts(opponent, dc, thunderbolts);
        		break;   		
        	case(7):
        		// Opponent loses health
        		//System.println("Case 8");
    			drawOpponent(opponent, dc);
        		if (healthRemaining > 0.1) { // Can't be 0 since 0.0000000 != 0 ...
        			sceneIdx--;
        			healthRemaining -= 0.20;
        		}
        		break;
        	case(8):
        		// Opponent faints (slides down)
        		//System.println("Case 9");
        		if (yOffset < 100) {
	    			drawOpponent(opponent, dc);
        			yOffset += 20;
        			dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_WHITE);
        			dc.fillRectangle(opponent.getPosX(), opponent.getPosY()+opponent.getBmpHeight()+10, 70, 80);
        			dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
        			drawSelf(pikachu, dc);
        			drawInfoBox(boxX, boxY, dc);
        			sceneIdx--;
        		}
        		// Prepare cases 10 and 11
        		sceneRepeat2 = 3;
        		sceneRepeat1 = 3;
        		break;
        	case(9):
        		// Opponent fainted!
        		//System.println("Case 10");
        		yOffset = 0;
        		healthRemaining = 1;
        		if (sceneRepeat2 > 0) {
        			sceneRepeat2--;
        			sceneIdx--;
	        		writeFainted(opponent, canvasW, boxY, dc);
        		}
        		break;
        	case(10):
        		// Victory!
        		//System.println("Case 11");
        		if (sceneRepeat1 > 0) {
        			sceneRepeat1--;
        			sceneIdx--;
	        		writeVictory(dc);
	        		break;
        		}
        		isAnimating = false;
        		break;
        	default:
        		//System.println("Case Default");
        		sceneIdx = -1;
        		break;	
        }
      
      	//System.println("End");
        sceneIdx++;
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
    
    	TIMER_1.stop();
    	TIMER_1 = new Timer.Timer();
    	TIMER_1.start(method(:timerCallback), timerDelay, false);
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() {
    	sceneIdx = 0;
    	isAnimating = true;
    	yOffset = 0;
    	timerDelay = 500;
	   	TIMER_1 = new Timer.Timer();
    	TIMER_1.start(method(:timerCallback), timerDelay, false);
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() {
    	sceneIdx = 0;
    	isAnimating = false;
    	healthRemaining = 1;
    	yOffset = 0;
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
        dc.drawText(canvasW/2, 20*canvasH/240, pokeTime, timeString, Gfx.TEXT_JUSTIFY_CENTER);
    }

    function writeOpponentAppears(opponent, canvasW, boxY, dc) {  
    	dc.drawText(canvasW/2, boxY + 12, pokeTextSmall, "A wild " + opponent.getName(), Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawText(canvasW/2, boxY + 25, pokeTextSmall, "appeared!", Gfx.TEXT_JUSTIFY_CENTER);
    }
    
    function writeThunder(canvasW, boxY, dc) {  
    	dc.drawText(canvasW/2, boxY + 12, pokeTextSmall, "Pikachu used", Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawText(canvasW/2, boxY + 25, pokeTextSmall, "Thunder!", Gfx.TEXT_JUSTIFY_CENTER);
    }
    
    function writeFainted(opponent, canvasW, boxY, dc) {        
        dc.drawText(canvasW/2, boxY + 12, pokeTextSmall, "Enemy " + opponent.getName(), Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawText(canvasW/2, boxY + 25, pokeTextSmall, "fainted!", Gfx.TEXT_JUSTIFY_CENTER);
    }
    
    function writeVictory(dc) {
    	dc.drawText(canvasW/2, boxY + 12, pokeTextSmall, "Victory!", Gfx.TEXT_JUSTIFY_CENTER);
    }
    
    function drawPokeBall(opponent, dc) {
    	dc.drawBitmap(opponent.getPosX(), opponent.getPosY()+35, pokeball);
    }
    
    function drawOpeningPokeBall(opponent, dc) {
    	dc.drawBitmap(opponent.getPosX()+10, opponent.getPosY()+35, pokeballOpening);
    }
    
    function drawThunderBolts(opponent, dc, thunderbolts) {
    	var centerX = opponent.getPosX() + opponent.getBmpWidth()/2;
    	var centerY = opponent.getPosY() +opponent.getBmpHeight()/2;
    	dc.setColor(Gfx.COLOR_YELLOW, Gfx.COLOR_WHITE);
    	dc.fillCircle(centerX, centerY, opponent.getBmpWidth()/3.5);
    	dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
    	var thunderW = thunderbolts.getWidth();
    	var thunderH = thunderbolts.getHeight();
    	dc.drawBitmap(centerX - thunderW/2, centerY - thunderH/2, thunderbolts);
    } 
    
    function drawOpponent(opponent, dc) { 
        var opponentPos = opponent.getPosXY();
        var opponentNamePos = canvasW > 240 ? [27, canvasH/4 + 5] : [17, canvasH/4 + 5];   
        
        lowerOpponentHealth(healthRemaining, dc);
		dc.drawBitmap(opponentPos[0], opponentPos[1] + yOffset, opponent.getBitmap());
        dc.drawText(opponentNamePos[0], opponentNamePos[1], pokeTextMedium, opponent.getName().toUpper(), Gfx.TEXT_JUSTIFY_LEFT);
        dc.drawText(opponentNamePos[0]+28, opponentNamePos[1]+15, pokeTextSmall, opponent.getLvl(), Gfx.TEXT_JUSTIFY_LEFT);
		dc.drawText(opponentNamePos[0]+3, opponentNamePos[1]+30, pokeTextTinyBold, "HP:", Gfx.TEXT_JUSTIFY_LEFT);
        dc.drawBitmap(opponentNamePos[0]-12, opponentNamePos[1]+15, halfBorderEnemy);
        dc.drawBitmap(opponentNamePos[0]+27, opponentNamePos[1]+32, healthEmpty);
    }

    function drawSelf(pikachu, dc) {
        var selfPos = pikachu.getPosXY();
        var selfNamePos = canvasW > 240 ? [canvasW/2-10, canvasH/2 + 20] : [canvasW/2-15, canvasH/2 + 20];
        
        dc.drawText(selfNamePos[0], selfNamePos[1], pokeTextMedium, pikachu.getName(), Gfx.TEXT_JUSTIFY_LEFT);
        dc.drawText(selfNamePos[0] + 50, selfNamePos[1] + 15, pokeTextSmall, pikachu.getLvl(), Gfx.TEXT_JUSTIFY_LEFT);
		dc.drawText(selfNamePos[0], selfNamePos[1] + 30, pokeTextTinyBold, "HP:", Gfx.TEXT_JUSTIFY_LEFT);
        dc.drawBitmap(selfNamePos[0] + 25, selfNamePos[1] + 32, healthEmpty);
        lowerSelfHealth(dc);
        dc.drawBitmap(selfNamePos[0] - 10, selfNamePos[1] + 20, halfBorderSelf);
        dc.drawBitmap(selfPos[0], selfPos[1], pikachu.getBitmap());
    }
    
    function drawInfoBox(boxX, boxY, dc) {
        dc.setPenWidth(2);
        dc.drawArc(canvasW/2, canvasH/2, canvasW/2 - 4, Gfx.ARC_COUNTER_CLOCKWISE, arcStart, arcEnd); 
        dc.drawLine(boxX + boxBallLeft.getWidth(), boxY + boxBallLeft.getHeight()/2+1,
        			 canvasW - boxX - boxBallRight.getWidth(), boxY + boxBallRight.getHeight()/2+1);
        dc.setPenWidth(1);
		dc.drawArc(canvasW/2, canvasH/2, canvasW/2 - 6, Gfx.ARC_COUNTER_CLOCKWISE, arcStart, arcEnd); 
        dc.drawLine(boxX + boxBallLeft.getWidth()-1, boxY + boxBallLeft.getHeight()/2-2,
        
        			 canvasW - boxX - boxBallRight.getWidth()+1, boxY + boxBallRight.getHeight()/2-2);
        dc.drawBitmap(boxX, boxY, boxBallLeft);
        dc.drawBitmap(canvasW - boxX - boxBallRight.getWidth(), boxY, boxBallRight);
    }
    
    // Fills the health bar according to remaining battery lvl
    function lowerOpponentHealth(healthRemaining, dc) {
        var opponentNamePos = canvasW > 240 ? [27, canvasH/4 + 5] : [17, canvasH/4 + 5];  
        var healthBarWidth = healthEmpty.getWidth() - 6; // Width of fillable part
        var hbwAdjusted = null;
    	
    	// Adjusting for rounding
        if (healthRemaining <= 0.1) {
        	hbwAdjusted = -3;
    	} else {
        	hbwAdjusted = healthBarWidth * healthRemaining + 2;
    	}
    	
		// Coloring the remaining health
        if (healthRemaining > 0.5) {
	        dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_WHITE);
    	} else if (healthRemaining > 0.21){
	        dc.setColor(Gfx.COLOR_YELLOW, Gfx.COLOR_WHITE);
		} else {
			dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_WHITE);
		}
    	
    	dc.fillRectangle(
    		opponentNamePos[0] + 29,
    		opponentNamePos[1] + 34,
    		Math.round(hbwAdjusted),
    		2
		);
		
		// Reset canvas color
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
    }
    
    // Returns the step progress in the form of a 
    function getStepProgress(integer) {
    	// step progress
      	var thisActivity = ActivityMonitor.getInfo();
		steps = thisActivity.steps;
		goal = thisActivity.stepGoal;
		// define our current step progress
		stepProgress = ((steps.toFloat()/goal.toFloat())*integer).toNumber();
		return stepProgress;
    }
    
    // Picks an opponent first based on % of step goal, then randomly
    function selectOpponent(opponentList) {
    	// step progress
		stepProgress = getStepProgress(3);
		if (stepProgress >= 6) {
			stepProgress = 3;
		} else {
			stepProgress = (stepProgress) >= 2 ? 2 : stepProgress % 3;
		} 
		switch(stepProgress) {
			case(0):
				pokemonPos = Math.rand() % 3;
				break;
			case(1):
			case(2):
				pokemonPos = Math.rand() % 2;
				break;
			case(3):
			default:
				pokemonPos = 0;
		}
		return opponentList[stepProgress][pokemonPos];
    }
    
   
    // Fills Pikachu's health according to remaining battery level
    function lowerSelfHealth(dc) {
    	var remainingBattery = Sys.getSystemStats().battery/100;
    	if (remainingBattery == null) {
    		remainingBattery = 0;
    	}
        var selfNamePos = canvasW > 240 ? [canvasW/2 - 12, canvasH/2 + 20] : [canvasW/2 - 17, canvasH/2 + 20];  
        var healthBarWidth = healthEmpty.getWidth() - 6; // Width of part to fill
        var hbwAdjusted = null;

        // Adjusting for rounding
        if (remainingBattery < 0.01) {
        	hbwAdjusted = -3;
    	} else {
	        hbwAdjusted = healthBarWidth * remainingBattery + 2;
		}    	

		// Coloring the remaining health
        if (remainingBattery > 0.5) {
	        dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_WHITE);
    	} else if (remainingBattery > 0.20){
	        dc.setColor(Gfx.COLOR_YELLOW, Gfx.COLOR_WHITE);
		} else {
			dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_WHITE);
		}
		
    	dc.fillRectangle(
    		selfNamePos[0] + 29,
    		selfNamePos[1] + 34,
    		Math.round(hbwAdjusted),
    		2
		);
		// Reset canvas color
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
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
	}
}
