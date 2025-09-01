internal class Program
{
    private static void Main(string[] args)
    {
        Console.WriteLine(Greet("Dayanand"));
        Console.WriteLine(CheckEvenOdd(7));
        Console.WriteLine($"Factorial of 5: {Factorial(5)}");
        Console.WriteLine($"Sunday is a {GetDayType(DayOfWeek.Sunday)}");
        Console.WriteLine($"37°C in Fahrenheit: {CelsiusToFahrenheit(37)}");
        Console.WriteLine($"Is 'madam' a palindrome? {IsPalindrome("madam")}");
        Console.WriteLine($"Reversed 'hello': {ReverseString("hello")}");
        Console.WriteLine($"Is 2024 a leap year? {IsLeapYear(2024)}");
        Console.WriteLine($"Random password: {GeneratePassword(12)}");
        Console.WriteLine($"Age for DOB 1990-08-28: {CalculateAge(new DateTime(1990, 8, 28))}");

        // Pause to allow profiling
        Console.WriteLine("Press any key to exit...");
        Console.ReadKey();

        string Greet(string name) => $"Hello, {name}! Welcome to C# 10.";

        string CheckEvenOdd(int number) => number switch
        {
            0 => "Zero is even.",
            _ when number % 2 == 0 => $"{number} is even.",
            _ => $"{number} is odd."
        };

        int Factorial(int n) => n <= 1 ? 1 : n * Factorial(n - 1);

        string GetDayType(DayOfWeek day) => day switch
        {
            DayOfWeek.Saturday or DayOfWeek.Sunday => "Weekend",
            _ => "Weekday"
        };

        double CelsiusToFahrenheit(double celsius) => celsius * 9 / 5 + 32;

        bool IsPalindrome(string input)
        {
            var reversed = new string(input.Reverse().ToArray());
            return input.Equals(reversed, StringComparison.OrdinalIgnoreCase);
        }

        string ReverseString(string input) => new string(input.Reverse().ToArray());

        bool IsLeapYear(int year) => DateTime.IsLeapYear(year);

        string GeneratePassword(int length)
        {
            const string chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*";
            var random = new Random();
            return new string(Enumerable.Range(0, length)
                .Select(_ => chars[random.Next(chars.Length)]).ToArray());
        }

        int CalculateAge(DateTime birthDate)
        {
            var today = DateTime.Today;
            var age = today.Year - birthDate.Year;
            if (birthDate.Date > today.AddYears(-age)) age--;
            return age;
        }
    }
}
