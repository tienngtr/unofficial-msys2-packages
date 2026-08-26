int python_target(int value)
{
    return value;
}

int python_caller(void)
{
    return python_target(1);
}

