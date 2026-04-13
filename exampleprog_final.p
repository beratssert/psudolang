// psudo final example program
// Demonstrates declarations, constants, assignments, functions,
// conditionals, loops, output, and exception handling.

CONST DECIMAL PI = 3.1415;
CONST TEXT WELCOME_MSG = "Welcome to psudo!";
CONST NUMBER MAX_RADIUS = 100;

NUMBER counter = 3;
DECIMAL radius = 2.0;
DECIMAL area;
BOOLEAN valid = FALSE;

FUNCTION calculateArea(DECIMAL r) DO
    DECIMAL result = PI * r * r;
    RETURN result;
END

TRY
    PRINT(WELCOME_MSG);
    PRINT("Using radius:");
    PRINT(radius);

    IF radius > MAX_RADIUS THEN
        THROW("RadiusTooLarge");
    ELSEIF radius > 0 THEN
        valid = TRUE;
        area = calculateArea(radius);

        PRINT("Calculated area:");
        PRINT(area);
    ELSE
        THROW("InvalidRadius");
    END

    IF valid == TRUE THEN
        PRINT("Countdown starts:");
        WHILE counter > 0 DO
            PRINT(counter);
            counter = counter - 1;
        END
    END

CATCH
    PRINT("An exception was caught.");
    PRINT("Program will continue safely.");
END

PRINT("Program finished.");