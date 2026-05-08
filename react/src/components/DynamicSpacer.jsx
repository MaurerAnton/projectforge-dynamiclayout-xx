import React from 'react';

function DynamicSpacer({ width }) {
    return <div style={{ width: width || 1, display: 'inline-block' }} />;
}

export default React.memo(DynamicSpacer);
