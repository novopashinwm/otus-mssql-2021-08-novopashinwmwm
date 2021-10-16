using System.Linq;
using System.Data;
using System.Data.SqlTypes;
using System.Text.RegularExpressions;
using System;

namespace CLRNovopashinWM
{
    public class DemoFunctionCLR
    {
        //Валидация
        //Алгоритм проверки банковских карт
        //https://ru.wikipedia.org/wiki/%D0%90%D0%BB%D0%B3%D0%BE%D1%80%D0%B8%D1%82%D0%BC_%D0%9B%D1%83%D0%BD%D0%B0
        public static SqlBoolean Luhn(SqlString value)
        {
            var digits = value.Value;
            var isResult = digits.All(char.IsDigit) && 
                digits.Reverse()
                .Select(c => c - 48)
                .Select((thisNum, i) => i % 2 == 0
                    ? thisNum
                    : ((thisNum *= 2) > 9 ? thisNum - 9 : thisNum)
                ).Sum() % 10 == 0;
            if (isResult) 
            {
                return SqlBoolean.True;
            }
            return SqlBoolean.False;
        }

        //Функция расширяющая возможности like, путем использования regex
        public static SqlBoolean MyLike(SqlString sqlInput, SqlString sqlPattern) 
        {
            var input = sqlInput.Value;
            var pattern = sqlPattern.Value;

            if (Regex.IsMatch(input, pattern)) {
                return SqlBoolean.True;
            }
            return SqlBoolean.False;
        }
    }
}
