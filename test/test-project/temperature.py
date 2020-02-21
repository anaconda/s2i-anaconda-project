from tranquilizer import tranquilize

@tranquilize(method='get')
def to_celsius(fahrenheit: float):
    '''Convert degrees Fahrenheit to degrees Celsius

    :param fahrenheit: Degrees fahrenheit'''

    return (fahrenheit - 32) * 5/9
