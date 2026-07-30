import re

EMAIL_PATTERN = re.compile(
    r"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"
)

def only_digits(value):

    return re.sub(r"\D", "", value or "")

def validate_phone(value):

    digits = only_digits(value)

    return len(digits) in (10, 11)

def validate_email(value):

    return bool(
        EMAIL_PATTERN.match((value or "").strip())
    )

def validate_cpf(digits):

    if len(digits) != 11 or digits == digits[0] * 11:

        return False

    first_sum = sum(
        int(digits[index]) * (10 - index)
        for index in range(9)
    )
    first_digit = (first_sum * 10) % 11
    if first_digit == 10:
        first_digit = 0

    second_sum = sum(
        int(digits[index]) * (11 - index)
        for index in range(10)
    )
    second_digit = (second_sum * 10) % 11
    if second_digit == 10:
        second_digit = 0

    return (
        first_digit == int(digits[9])
        and second_digit == int(digits[10])
    )

def validate_cnpj(digits):

    if len(digits) != 14 or digits == digits[0] * 14:

        return False

    first_weights = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]
    second_weights = [6] + first_weights

    first_sum = sum(
        int(digit) * weight
        for digit, weight in zip(digits[:12], first_weights)
    )
    first_digit = 11 - (first_sum % 11)
    if first_digit >= 10:
        first_digit = 0

    second_sum = sum(
        int(digit) * weight
        for digit, weight in zip(digits[:13], second_weights)
    )
    second_digit = 11 - (second_sum % 11)
    if second_digit >= 10:
        second_digit = 0

    return (
        first_digit == int(digits[12])
        and second_digit == int(digits[13])
    )

def validate_document(value):

    digits = only_digits(value)

    if len(digits) == 11 and validate_cpf(digits):

        return True

    if len(digits) == 14 and validate_cnpj(digits):

        return True

    return False

def format_phone(value):

    digits = only_digits(value)

    if len(digits) == 11:

        return (
            f"({digits[:2]}) "
            f"{digits[2:7]}-{digits[7:]}"
        )

    if len(digits) == 10:

        return (
            f"({digits[:2]}) "
            f"{digits[2:6]}-{digits[6:]}"
        )

    return value

def format_document(value):

    digits = only_digits(value)

    if len(digits) == 11:

        return (
            f"{digits[:3]}.{digits[3:6]}."
            f"{digits[6:9]}-{digits[9:]}"
        )

    if len(digits) == 14:

        return (
            f"{digits[:2]}.{digits[2:5]}."
            f"{digits[5:8]}/{digits[8:12]}-"
            f"{digits[12:]}"
        )

    return value
