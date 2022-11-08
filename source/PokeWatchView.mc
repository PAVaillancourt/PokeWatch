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
    
    // Self pokemon
    var pokemonSelfIdx = null;
    var pokemonSelf = null;
    var thunderbolts = null;
    var emberBig = null;
    var emberSmall = null;

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
    var settingsChangedSinceLastDraw = false;
    
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
        charmander.setBitmap(Ui.loadResource(Rez.Drawables.charmander));       

	    squirtle = new pokemon("Squirtle",":L8",170*canvasW/240,75*canvasH/240);
        squirtle.setBitmap(Ui.loadResource(Rez.Drawables.squirtle));

	    bulbasaur = new pokemon("Bulbasaur",":L15",170,posY70);
        bulbasaur.setBitmap(Ui.loadResource(Rez.Drawables.bulbasaur));

	    ivysaur = new pokemon("Ivysaur",":L16",posX160,posY70);
        ivysaur.setBitmap(Ui.loadResource(Rez.Drawables.ivysaur));

	    wartortle = new pokemon("Wartortle",":L23",posX160,posY70);
        wartortle.setBitmap(Ui.loadResource(Rez.Drawables.wartortle));

	    charizard = new pokemon("Charizard",":L42",posX160,posY70);
        charizard.setBitmap(Ui.loadResource(Rez.Drawables.charizard));

	    blastoise = new pokemon("Blastoise",":L69",posX160,posY70);
        blastoise.setBitmap(Ui.loadResource(Rez.Drawables.blastoise));
	    
	    missingno = new pokemon("Missigno",":L99",posX160,posY70);
        missingno.setBitmap(Ui.loadResource(Rez.Drawables.missingno)); 

	    pokemonSelfIdx = App.getApp().getProperty("YourPokemon");
	    
	    pokemonSelf = assignPokemonSelf(pokemonSelfIdx);

        opponentList = [[charmander, bulbasaur, squirtle], [ivysaur, wartortle], [charizard, blastoise], [missingno]];
        
        // Animations
        thunderbolts = Ui.loadResource(Rez.Drawables.thunderbolts);
        emberSmall = Ui.loadResource(Rez.Drawables.emberSmall);
        emberBig = Ui.loadResource(Rez.Drawables.emberBig);
        pokeballOpening = Ui.loadResource(Rez.Drawables.pokeballOpening);
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    }

    // Update the view
    function onUpdate(dc) {	
    	
    	// Change pokemon if settings have been changed
    	if (settingsChangedSinceLastDraw) {
			applySettingsChanges();
    	}
    	
    	// Clear canvas
    	dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_WHITE);
        dc.clear();
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);

        // Draw "constant" components
		drawTime(dc);
		if (App.getApp().getProperty("ShowDate")) {
			drawDate(dc);
		}
		if (App.getApp().getProperty("ShowSteps")) {
			drawSteps(dc);
		}
        drawSelf(pokemonSelf, dc);
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
        		// Pokemon uses its attack!
        		//System.println("Case 3");
        		drawOpponent(opponent, dc);
        		writeAttack(pokemonSelf.getName(), pokemonSelf.getAttack(), canvasW, boxY, dc);
        		if (sceneRepeat2 > 0) {
	        		sceneRepeat2--;
	        		sceneIdx--;
        		}
        		break;
        	case(4):
        		// Frame 1/3 of attack
        		//System.println("Case 4");
        		drawOpponent(opponent, dc);
        		drawAttack(pokemonSelf, opponent, 1, dc, thunderbolts);
        		writeAttack(pokemonSelf.getName(), pokemonSelf.getAttack(), canvasW, boxY, dc);
        		break;
        	case(5):
        		// Frame 2/3 of attack
        		//System.println("Case 5");
        		// Special treatment for thunder
				if (pokemonSelf.getAttack().equals("Thunder")) {
	        		// Thunderbolts visible, black bckgrnd
	        		dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
	        		dc.clear();
	        		drawTime(dc);
	        		drawSelf(pokemonSelf, dc);
	        		drawInfoBox(boxX, boxY, dc);
        		}
        		drawOpponent(opponent, dc);
        		writeAttack(pokemonSelf.getName(), pokemonSelf.getAttack(), canvasW, boxY, dc);
        		drawAttack(pokemonSelf, opponent, 2, dc, thunderbolts);
        		break;
        	case(6):
        		// Frame 3/3 of attack
        		//System.println("Case 6");
        		drawOpponent(opponent, dc);
        		writeAttack(pokemonSelf.getName(), pokemonSelf.getAttack(), canvasW, boxY, dc);
        		drawAttack(pokemonSelf, opponent, 3, dc, thunderbolts);
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
        			drawSelf(pokemonSelf, dc);
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
    	// Kill active timer
    	if (TIMER_1) {
    		TIMER_1.stop();
		}	
		sceneIdx = 0;
    	isAnimating = false;
    	healthRemaining = 1;
    	yOffset = 0;
    	timerDelay = 1000;
    	Ui.requestUpdate();
    }
    
    // Animation loop callback
    function timerCallback() {
    	// Redraw the canvas
    	Ui.requestUpdate();
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() {
		try {
			sceneIdx = 0;
    		isAnimating = true;
    		yOffset = 0;
    		timerDelay = 500;
    		if (TIMER_1 == null) {
	   			TIMER_1 = new Timer.Timer();
			}
			TIMER_1.start(method(:timerCallback), timerDelay, true);
		}
		catch( ex ) {
			onEnterSleep();
		}
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() {
    	// Kill active timer
    	if (TIMER_1) {
    		TIMER_1.stop();
		}
    	sceneIdx = 0;
    	isAnimating = false;
    	healthRemaining = 1;
    	yOffset = 0;
    	timerDelay = 1000;
    	Ui.requestUpdate();
    }
    
    // Sets a "settings changed" flag for the next screen update
    function onSettingsChanged() {
    	settingsChangedSinceLastDraw = true;
    	return null;	
    } 
    
    // Makes changes according to the most recent settings
    function applySettingsChanges() {
		pokemonSelfIdx = App.getApp().getProperty("YourPokemon");
		pokemonSelf = assignPokemonSelf(pokemonSelfIdx);
		if (!App.getApp().getProperty("CustomName").equals("")) {
			pokemonSelf.setName(App.getApp().getProperty("CustomName"));
		}
		settingsChangedSinceLastDraw = false;
    }
    
    function drawTime(dc) {
    	// Get time
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
        dc.drawText(canvasW/2, 18*canvasH/240, pokeTime, timeString, Gfx.TEXT_JUSTIFY_CENTER);
    }
    
    function drawDate(dc) {
    	// Get date
		var date = Time.Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        var day = date.day;
        var month = date.month;
        var year = date.year;
        var day_of_week = Time.Gregorian.info(Time.now(), Time.FORMAT_MEDIUM).day_of_week;
    	
    	var dateString = Lang.format("$1$ $2$", [month, day]);
    	dc.drawText(canvasW/2, 8*canvasH/240, pokeTextSmall, dateString, Gfx.TEXT_JUSTIFY_CENTER);
    	
    	return null;
    }

	function drawSteps(dc) {
		// Get steps
		var steps = getSteps();
		var stepsString = Lang.format("$1$", [steps]);
		dc.drawText(canvasW/2, 40*canvasH/240, pokeTextSmall, stepsString, Gfx.TEXT_JUSTIFY_CENTER);

	}

    function writeOpponentAppears(opponent, canvasW, boxY, dc) {  
    	dc.drawText(canvasW/2, boxY + 12, pokeTextSmall, "A wild " + opponent.getName(), Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawText(canvasW/2, boxY + 25, pokeTextSmall, "appeared!", Gfx.TEXT_JUSTIFY_CENTER);
    }
    
    function writeAttack(selfName, selfAttack, canvasW, boxY, dc) {  
    	dc.drawText(canvasW/2, boxY + 12, pokeTextSmall, selfName+" used", Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawText(canvasW/2, boxY + 25, pokeTextSmall, selfAttack+"!", Gfx.TEXT_JUSTIFY_CENTER);
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
    
    // Draws a double-colored, triple-layered ellipse
    function drawPsyEllipse(x, y, radX, radY, dc) {
    	// Outer ellipse
    	dc.setColor(Gfx.COLOR_PURPLE, Gfx.COLOR_TRANSPARENT);
    	dc.setPenWidth(4);
    	dc.drawEllipse(x, y, radX, radY);
    	
    	// Inner (white) ellipse
    	dc.setPenWidth(2);
    	dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
    	dc.drawEllipse(x, y, radX, radY);
    	
    	// Clean up
    	dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
    }
    
    function drawPsywave(pokemonSelf, attackIdx, dc) {
    	var currentRelXY = pokemonSelf.getPosXY();
    	currentRelXY[0] = currentRelXY[0]+pokemonSelf.getBmpWidth();
    	var radX = [7, 10, 13];
    	var radY = [13, 17, 22];
    	
    	switch(attackIdx) {
    		case(3):
    		case(2):
				drawPsyEllipse(currentRelXY[0]+50, currentRelXY[1]-40, radX[2], radY[2], dc);
				drawPsyEllipse(currentRelXY[0]+65, currentRelXY[1]-28, radX[2], radY[2], dc);
				drawPsyEllipse(currentRelXY[0]+22, currentRelXY[1]-20, radX[1], radY[2], dc);
				drawPsyEllipse(currentRelXY[0]+37, currentRelXY[1]-8, radX[1], radY[2], dc);    
			case(1):
				drawPsyEllipse(currentRelXY[0]-10, currentRelXY[1], radX[0], radY[0], dc);
				drawPsyEllipse(currentRelXY[0]+5, currentRelXY[1]+12, radX[0], radY[0], dc);
			default:
				break;
		}
    }
    
    function drawEmbers(opponent, attackIdx, emberSmall, emberBig, dc) {
    	var opponentXY = opponent.getPosXY();
    	opponentXY[1] = opponentXY[1] + opponent.getBmpHeight(); 
    	
    	switch(attackIdx) {
    		case(1):
    			dc.drawBitmap(opponentXY[0], opponentXY[1]-emberSmall.getHeight(), emberSmall);
    			dc.drawBitmap(opponentXY[0]+25, opponentXY[1]-emberSmall.getHeight(), emberSmall);
    			break;
    		case(2):
    			dc.drawBitmap(opponentXY[0], opponentXY[1]-emberBig.getHeight(), emberBig);
    			dc.drawBitmap(opponentXY[0]+25, opponentXY[1]-emberBig.getHeight(), emberBig);
    			break;
    		case(3):
    			dc.drawBitmap(opponentXY[0], opponentXY[1]-emberSmall.getHeight(), emberSmall);
    			dc.drawBitmap(opponentXY[0]+25, opponentXY[1]-emberSmall.getHeight(), emberSmall);
    			break;
    		default:
    			break;
    	}
    }
    
    function drawBubbles(pokemonSelf, attackIdx, dc) {
    	var currentRelXY = pokemonSelf.getPosXY();
    	currentRelXY[0] = currentRelXY[0]+pokemonSelf.getBmpWidth();
    	var smallRadius = 5;
    	var bigRadius = 11;
    	var bigBubbleXY = null;
    	
    	dc.setPenWidth(2);
    	
    	switch(attackIdx) {
    		case(3):
    		case(2):    			
    			bigBubbleXY = [
    				currentRelXY[0]+bigRadius*8-15,
		        	currentRelXY[1]-bigRadius*4
		        	];
		        
		        // Small bubbles
		        drawSmallBubble(
		        	bigBubbleXY[0]-5,
		        	bigBubbleXY[1]-bigRadius-smallRadius-3,
		        	smallRadius,
		        	dc
		        	);
		        drawSmallBubble(
		        	bigBubbleXY[0]+bigRadius+smallRadius+5,
		        	bigBubbleXY[1]+bigRadius+2,
		        	smallRadius,
		        	dc
		        	);
		        drawSmallBubble(
		        	bigBubbleXY[0]-3,
		        	bigBubbleXY[1]+bigRadius+smallRadius+1,
		        	smallRadius,
		        	dc
		        	);
		       
		        // Big bubbles
		        dc.setPenWidth(3);
		        dc.drawArc(
		        	bigBubbleXY[0]+3, //x
		        	bigBubbleXY[1]-bigRadius, // y
		        	bigRadius, //radius
		        	Gfx.ARC_CLOCKWISE, //clck or ctrclck
		        	105, //degStart
		        	0 //degEnd
		        	);
		        dc.drawArc(
		        	bigBubbleXY[0],
		        	bigBubbleXY[1],
		        	bigRadius,
		        	Gfx.ARC_CLOCKWISE, //clck or ctrclck
		        	0, //degStart
		        	88 //degEnd
		        	);
		        dc.drawCircle(
		        	bigBubbleXY[0]+bigRadius,
		        	bigBubbleXY[1]-4,
		        	bigRadius
		        	);

    		case(1):
    			bigBubbleXY = [
    				currentRelXY[0]+bigRadius*4-1,
		        	currentRelXY[1]-10
		        	];
		        
		        // Small bubbles
		        dc.setPenWidth(2);
		        drawSmallBubble(
		        	bigBubbleXY[0]-smallRadius,
		        	bigBubbleXY[1]-bigRadius-smallRadius-3,
		        	smallRadius,
		        	dc
		        	);
		        drawSmallBubble(
		        	bigBubbleXY[0]+smallRadius+1,
		        	bigBubbleXY[1]-bigRadius-smallRadius+1,
		        	smallRadius,
		        	dc
		        	);
		        drawSmallBubble(
		        	bigBubbleXY[0]-smallRadius,
		        	bigBubbleXY[1]+bigRadius+smallRadius+3,
		        	smallRadius,
		        	dc
		        	);
		        drawSmallBubble(
		        	bigBubbleXY[0]+bigRadius+smallRadius+2,
		        	bigBubbleXY[1]+smallRadius,
		        	smallRadius,
		        	dc
		        	);
		        
		        // Big bubbles
		        dc.setPenWidth(3);
		        dc.drawCircle(
		        	bigBubbleXY[0]-bigRadius*2-8,
		        	bigBubbleXY[1],
		        	bigRadius
		        	);
		        dc.drawCircle(
		        	bigBubbleXY[0],
		        	bigBubbleXY[1],
		        	bigRadius
		        	);
	     	default:
	     		break;	
    	}
    }
    
    // Draw a single small bubble with an interior arc for 3d effect
    function drawSmallBubble(x, y, radius, dc) {
        dc.drawCircle(x, y, radius);
        dc.drawArc(x, y, radius-1, Gfx.ARC_CLOCKWISE, 0, 270 );
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

    // Draws the player's pokemon and the associated infobox
    function drawSelf(pokemonSelf, dc) {
        var selfPos = pokemonSelf.getPosXY();
        var selfNamePos = canvasW > 240 ? [canvasW/2-10, canvasH/2 + 20] : [canvasW/2-15, canvasH/2 + 20];
		var pokemonSelfLvl = getStepProgress(99) > 100 ? 99 : getStepProgress(99);
		pokemonSelfLvl = pokemonSelfLvl < 4 ? 4 : pokemonSelfLvl;
		pokemonSelf.setLvl(":L" + (pokemonSelfLvl.toString()));
        
        dc.drawText(selfNamePos[0], selfNamePos[1], pokeTextMedium, pokemonSelf.getName().toUpper(), Gfx.TEXT_JUSTIFY_LEFT);
        dc.drawText(selfNamePos[0] + 50, selfNamePos[1] + 15, pokeTextSmall, pokemonSelf.getLvl(), Gfx.TEXT_JUSTIFY_LEFT);
		dc.drawText(selfNamePos[0], selfNamePos[1] + 30, pokeTextTinyBold, "HP:", Gfx.TEXT_JUSTIFY_LEFT);
        dc.drawBitmap(selfNamePos[0] + 25, selfNamePos[1] + 32, healthEmpty);
        lowerSelfHealth(dc);
        dc.drawBitmap(selfNamePos[0] - 10, selfNamePos[1] + 20, halfBorderSelf);
        dc.drawBitmap(selfPos[0], selfPos[1], pokemonSelf.getBitmap());
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
    
    // Returns the step progress in the form of an integer between 0 and 100
    function getStepProgress(integer) {
    	// step progress
      	var thisActivity = ActivityMonitor.getInfo();
		steps = thisActivity.steps;
		goal = thisActivity.stepGoal;
		// define our current step progress
		stepProgress = ((steps.toFloat()/goal.toFloat())*integer).toNumber();
		return stepProgress;
    }

	// Returns the number of hundreds of steps as an integer 
	function getSteps() {
		var thisActivity = ActivityMonitor.getInfo();
		return thisActivity.steps;
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
    
   
    // Fills our pokemon's health according to remaining battery level
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
    
	function drawAttack(pokemonSelf, opponent, attackAnimationIdx, dc, thunderbolts) {
		switch(pokemonSelf.getAttack()) {
			case("Thunder"):
				drawThunderBolts(opponent, dc, thunderbolts);
				break;
			case("Psywave"):
				drawPsywave(pokemonSelf, attackAnimationIdx, dc);
				break;
			case("Ember"):
				drawEmbers(opponent, attackAnimationIdx, emberSmall, emberBig, dc);
				break;
			case("Bubble"):
				drawBubbles(pokemonSelf, attackAnimationIdx, dc);
				break;
			default:
				break;
		}
	}
    
    function assignPokemonSelf(pokemonSelfIdx) {
    	switch (pokemonSelfIdx) {
			case(0):
				// Pikachu
			    pokemonSelf = new pokemon("Pikachu", ":L", 40*canvasW/240,148*canvasH/240);
		        pokemonSelf.setBitmap(Ui.loadResource(Rez.Drawables.pikachuBack));
		        pokemonSelf.setAttack("Thunder");
				break;
			case(1):
				// Squirtle
			    pokemonSelf = new pokemon("Squirtle", ":L", 47*canvasW/240,159*canvasH/240);
		        pokemonSelf.setBitmap(Ui.loadResource(Rez.Drawables.squirtleBack));
		        pokemonSelf.setAttack("Bubble");
				break;
			case(2):
				// Flareon
			    pokemonSelf = new pokemon("Flareon", ":L", 46*canvasW/240,150*canvasH/240);
		        pokemonSelf.setBitmap(Ui.loadResource(Rez.Drawables.flareonBack));
		        pokemonSelf.setAttack("Ember");
				break;
			case(3):
				// Mew
			    pokemonSelf = new pokemon("Mew", ":L", 35*canvasW/240,133*canvasH/240);
		        pokemonSelf.setBitmap(Ui.loadResource(Rez.Drawables.mewBack));
		        pokemonSelf.setAttack("Psywave");
		        break;
		    case(4):
		    	// Mewtwo
			    pokemonSelf = new pokemon("Mewtwo", ":L", 46*canvasW/240,150*canvasH/240);
		        pokemonSelf.setBitmap(Ui.loadResource(Rez.Drawables.mewtwoBack));
		        pokemonSelf.setAttack("Psywave");
		        break;
			//case(1):
			//	// Eevee
			//    pokemonSelf = new pokemon("Eevee", ":L", 42*canvasW/240,152*canvasH/240);
		    //    pokemonSelf.setBitmap(Ui.loadResource(Rez.Drawables.eeveeBack));
		    //    pokemonSelf.setAttack("Tackle");
			//	break;
			default:
				break;
	    }
	    return pokemonSelf;
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
			self.posX = posX;
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
