import React from 'react';
import DynamicBadge from './DynamicBadge';

function DynamicBadgeList({ badgeList }) {
    if (!badgeList || badgeList.length === 0) return null;

    return (
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.25rem' }}>
            {badgeList.map((badge, idx) => (
                <DynamicBadge key={idx} {...badge} />
            ))}
        </div>
    );
}

export default React.memo(DynamicBadgeList);
