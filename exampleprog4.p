CONST DECIMAL PI = 3.1415;
DECIMAL radius = 2.0;

FUNCTION calculateArea(DECIMAL r) DO
    DECIMAL result = PI * r * r;
    RETURN result;
END

DECIMAL area = calculateArea(radius);
PRINT(area);