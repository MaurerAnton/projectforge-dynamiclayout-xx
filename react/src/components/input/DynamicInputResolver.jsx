import React from 'react';
import DynamicInput from './DynamicInput';
import DynamicDateInput from './DynamicDateInput';
import DynamicTimeInput from './DynamicTimeInput';
import DynamicTimestampInput from './DynamicTimestampInput';
import DynamicReadonlyField from './DynamicReadonlyField';

function DynamicInputResolver(props) {
    const { dataType } = props;

    switch (dataType) {
        case 'DATE':
            return <DynamicDateInput {...props} />;
        case 'TIME':
            return <DynamicTimeInput {...props} />;
        case 'TIMESTAMP':
            return <DynamicTimestampInput {...props} />;
        case 'INT':
        case 'LONG':
        case 'DECIMAL':
        case 'NUMBER':
        case 'AMOUNT':
            return <DynamicInput type="number" {...props} />;
        case 'PASSWORD':
            return <DynamicInput type="password" {...props} />;
        case 'READONLY':
        case 'READONLY_FIELD':
            return <DynamicReadonlyField {...props} />;
        case 'STRING':
        default:
            return <DynamicInput {...props} />;
    }
}

export default React.memo(DynamicInputResolver);
