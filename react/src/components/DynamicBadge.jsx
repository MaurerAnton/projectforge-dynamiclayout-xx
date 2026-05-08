import React from 'react';

const colorMap = {
    primary: '#0d6efd',
    secondary: '#6c757d',
    success: '#198754',
    danger: '#dc3545',
    warning: '#ffc107',
    info: '#0dcaf0',
    light: '#f8f9fa',
    dark: '#212529',
};

function DynamicBadge({ title, color, pill }) {
    return (
        <span style={{
            display: 'inline-block',
            padding: '0.25em 0.5em',
            fontSize: '0.75em',
            fontWeight: 700,
            backgroundColor: colorMap[color] || colorMap.secondary,
            color: '#fff',
            borderRadius: pill ? '50rem' : '0.25rem',
            marginRight: '0.25rem',
        }}>
            {title}
        </span>
    );
}

export default React.memo(DynamicBadge);
