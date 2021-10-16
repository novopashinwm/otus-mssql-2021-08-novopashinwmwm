using Microsoft.SqlServer.Server;

using System;
using System.Data.SqlTypes;
using System.IO;
using System.Text;

namespace CLRNovopashinWM
{
    [Serializable]
    [SqlUserDefinedAggregate(
       Format.UserDefined, /// Binary Serialization because of StringBuilder
       IsInvariantToOrder = false, /// order changes the result
       IsInvariantToNulls = true,  /// nulls don't change the result
       IsInvariantToDuplicates = false, /// duplicates change the result
       MaxByteSize = -1 )]
    public struct MySTRING_AGG : IAggregate, IBinarySerialize
    {
        private StringBuilder _accumulator;
        private string _delimiter;
        
        /// <summary>
        /// IsNull property
        /// </summary>
        public Boolean IsNull { get; private set; }

        public void Accumulate(SqlString Value, SqlString Delimiter)
        {

            if (!Delimiter.IsNull  && Delimiter.Value.Length > 0)
            {
                _delimiter = Delimiter.Value; /// save for Merge
                if (_accumulator.Length > 0) _accumulator.Append(Delimiter.Value);
            }

            _accumulator.Append(Value.Value);
            if (Value.IsNull == false) this.IsNull = false;

        }

        public void Init()
        {
            _accumulator = new StringBuilder();
            _delimiter = string.Empty;
            this.IsNull = true;
        }

        public void Merge(MySTRING_AGG group)
        {
            /// add the delimiter between strings
            if (_accumulator.Length > 0 && group._accumulator.Length > 0) 
                _accumulator.Append(_delimiter);
            _accumulator.Append(group._accumulator.ToString());
        }

        public void Read(BinaryReader r)
        {
            _delimiter = r.ReadString();
            _accumulator = new StringBuilder(r.ReadString());
            if (_accumulator.Length != 0) 
                this.IsNull = false;
        }

        public SqlString Terminate()
        {
            return new SqlString(_accumulator.ToString());
        }

        public void Write(BinaryWriter w)
        {
            w.Write(_delimiter);
            w.Write(_accumulator.ToString());
        }
    }
}