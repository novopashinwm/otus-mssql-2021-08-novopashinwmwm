using Microsoft.SqlServer.Server;

using System;
using System.Data.SqlTypes;
using System.IO;
using System.Text.RegularExpressions;

namespace CLRNovopashinWM
{
    [Serializable]
    [SqlUserDefinedType(
    Format.UserDefined,
    IsByteOrdered = true,
    IsFixedLength = false,
    MaxByteSize = 11)]
    public class RuPassport : INullable, IBinarySerialize
    {
        // Поле для хранения значения
        private string _number;


        public SqlString Number
        {
            get
            {
                return new SqlString(_number);
            }

            set
            {
                if (value == SqlString.Null)
                {
                    _number = string.Empty;
                    return;
                }

                string str = (string)value;

                if (Regex.IsMatch(str, "[0-9]{10}"))
                {
                    _number = str;
                }
                else
                {
                    throw new ArgumentException(
                        "Phone numbers must be 10 digits.");
                }
            }
        }

        public override string ToString()
        {
            return string.Format("{0} {1} {2}", _number.Substring(0,2), 
                _number.Substring(2,2), _number.Substring(4,6));
        }

        public bool IsNull => string.IsNullOrEmpty(_number);

        public static RuPassport Null
        {
            // Это тот же Null,
            // что видели раньше во встроенных типах:
            // SqlString.Null, SqlInt32.Null
            get
            {
                RuPassport passport = new RuPassport();
                passport._number = string.Empty;
                return passport;
            }
        }

        public static RuPassport Parse(SqlString s)
        {
            if (s.IsNull)
                return RuPassport.Null;

            RuPassport passport = new RuPassport();
            passport.Number = s;

            return passport;
        }

        public void Read(BinaryReader r)
        {
            _number = r.ReadString();
        }

        public void Write(BinaryWriter w)
        {
            w.Write(_number);
        }
    }
}
