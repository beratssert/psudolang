TRY
    PRINT("before");
    THROW("SomeError");
    PRINT("after");
CATCH
    PRINT("caught");
END

FUNCTION boom() DO
    THROW("Boom");
    RETURN 0;
END

TRY
    PRINT("start");
    PRINT(boom());
    PRINT("after");
CATCH
    PRINT("caught from function");
END