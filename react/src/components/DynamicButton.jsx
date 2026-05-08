import React from 'react';
import DynamicLayoutContext from '../context';

function DynamicButton({ id, title, color, default: isDefault, disabled, confirmMessage, responseAction }) {
    const { callAction } = React.useContext(DynamicLayoutContext);

    const handleClick = () => {
        if (confirmMessage) {
            if (!window.confirm(confirmMessage)) return;
        }
        if (callAction) {
            callAction({ id, responseAction });
        }
    };

    const colorMap = {
        primary: '#0d6efd',
        secondary: '#6c757d',
        success: '#198754',
        danger: '#dc3545',
        warning: '#ffc107',
        info: '#0dcaf0',
        light: '#f8f9fa',
        dark: '#212529',
        link: 'transparent',
    };

    return (
        <button
            type={isDefault ? 'submit' : 'button'}
            onClick={handleClick}
            disabled={disabled}
            style={{
                backgroundColor: colorMap[color] || colorMap.secondary,
                color: color === 'warning' || color === 'light' ? '#000' : '#fff',
                border: 'none',
                borderRadius: '4px',
                padding: '6px 16px',
                cursor: disabled ? 'not-allowed' : 'pointer',
                opacity: disabled ? 0.65 : 1,
                fontWeight: 500,
                marginRight: '0.5rem',
            }}
        >
            {title || id}
        </button>
    );
}

export default React.memo(DynamicButton);
