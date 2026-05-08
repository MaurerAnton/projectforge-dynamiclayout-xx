import React from 'react';

function DynamicActionGroup({ actions }) {
    if (!actions || actions.length === 0) return null;

    return (
        <div style={{
            display: 'flex',
            gap: '0.5rem',
            padding: '16px 0',
            borderTop: '1px solid #dee2e6',
            marginTop: '16px',
        }}>
            {actions.map((action, idx) => (
                <ActionButton key={action.key || idx} action={action} />
            ))}
        </div>
    );
}

import DynamicButton from '../components/DynamicButton';

function ActionButton({ action }) {
    return <DynamicButton {...action} />;
}

export default React.memo(DynamicActionGroup);
