using Toybox.Application;
//using Toybox.WatchUi;

class PokeWatchApp extends Application.AppBase {

	var pokeView;
	
    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state) {
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    }

    // Return the initial view of your application here
    function getInitialView() {
    	pokeView = new PokeWatchView();
    	onSettingsChanged();
        return [ pokeView ];
    }

    // New app settings have been received so trigger a UI update
    function onSettingsChanged() {
    	pokeView.onSettingsChanged();
        WatchUi.requestUpdate();
    }

}