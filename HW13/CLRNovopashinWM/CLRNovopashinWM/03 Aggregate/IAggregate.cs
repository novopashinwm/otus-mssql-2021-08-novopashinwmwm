using System;
using System.Collections.Generic;
using System.Data.SqlTypes;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CLRNovopashinWM
{
    interface IAggregate
    {
        void Init();
        void Accumulate(SqlString value, SqlString Delimiter);
        void Merge(MySTRING_AGG group);
        SqlString Terminate();
    }
}
