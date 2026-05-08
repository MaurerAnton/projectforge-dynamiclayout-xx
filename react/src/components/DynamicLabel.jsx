import React from 'react';

function DynamicLabel({ label, tooltip }) {
    return (
        <label style={{
            display: 'block',
            marginBottom: '0.25rem',
            fontWeight: 500,
        }}>
            {label}
            {tooltip && (
                <span title={tooltip} style={{ marginLeft: '0.25rem', cursor: 'help', color: '#888' }}>ⓘ</span>
            )}
        </label>
    );
}

export default React.memo(DynamicLabel);
