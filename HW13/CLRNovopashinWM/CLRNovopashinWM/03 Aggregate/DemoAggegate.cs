using Microsoft.SqlServer.Server;

using System;
using System.Data.SqlTypes;
using System.IO;
using System.Text;

namespace CLRNovopashinWM
{
    public struct DemoAggegate : IAggregate, IBinarySerialize
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

        public void Merge(DemoAggegate group)
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
