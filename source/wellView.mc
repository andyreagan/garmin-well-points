import Toybox.Activity;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;
import Toybox.UserProfile;
import Toybox.Time.Gregorian;
import Toybox.System;

class wellView extends WatchUi.SimpleDataField {
    private var _wellPoints = 0.0;
    private var _bmrPerDay = 2000;
    private var _targetHours = 35;

    // Set the label of the data field here.
    function initialize() {
        SimpleDataField.initialize();
        label = "WELL Points";

        var profile = UserProfile.getProfile();
        // gender is 0/1/2  for F/M/Unspecified
        var gender = profile.gender;
        // use the height, weight, age, and gender to calculate BMR
        if (profile.height != null && profile.weight != null && profile.birthYear != null) {
            var height = profile.height;
            var weight = profile.weight / 1000;
            // age from profile.birthYear
            var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
            var age = today.year - profile.birthYear;

            // BMR calculation using Mifflin-St Jeor Equation
            if (gender == UserProfile.GENDER_MALE) {
                _bmrPerDay = 5.2 - 6.116 * age + 7.628 * height + 12.2 * weight;
            } else {// female
                _bmrPerDay = -197.6 - 6.116 * age + 7.628 * height + 12.2 * weight;
            }
        } else {
            if (gender == UserProfile.GENDER_MALE) {
                _bmrPerDay = 2000;
            } else if (gender == UserProfile.GENDER_FEMALE) {
                _bmrPerDay = 1800;
            } else {
                _bmrPerDay = 1900;
            }
        }
        // System.println(_bmrPerDay);
        // help from https://forums.garmin.com/developer/connect-iq/f/discussion/208338/active-calories#pifragment-1298=2
    }

    function compute(info as Activity.Info) as Numeric or Duration or String or Null {
        if (info.calories == null) {
            return "0";
        }
        var totalCalories = info.calories;

        // Calculate WELL Points
        // 1000 points = targetHours * (bmrPerDay/24) calories
        var caloriesPerPoint = (_bmrPerDay / 24.0 * _targetHours) / 1000.0;
        // System.println("caloriesPerPoint: " + caloriesPerPoint);
        // the caloriesPerPoint could be computed in the initialize() method...

        // Subtract the BMR calories from the active calories
        // Note: use timerTime instead of elapsedTime, so points don't go down when paused
        var elapsedHours = info.timerTime / 1000.0 / 60.0 / 60.0;
        // System.println("elapsedHours: " + elapsedHours);
        var basalCalories = _bmrPerDay / 24.0 * elapsedHours;
        // System.println("basalCalories: " + basalCalories);
        var activeCalories = totalCalories - basalCalories;
        // System.println("activeCalories: " + activeCalories);
        var wellPoints = activeCalories / caloriesPerPoint;

        if (wellPoints < 0) {
            wellPoints = 0.0;
        }
        System.println("wellPoints: " + wellPoints + " _wellPoints: " + _wellPoints);
        // don't allow them to decrease
        if (wellPoints > _wellPoints) {
            _wellPoints = wellPoints;
        }
        return Math.floor(_wellPoints).format("%.0f");
    }
}
