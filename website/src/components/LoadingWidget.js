import React, { Component } from 'react';
import './LoadingWidget.css';
import Loading from 'react-loading-components';

class LoadingWidget extends Component {
    render() {
        return (
            <div className="LoadingWidget">
                <Loading type="tail_spin" width={40} height={40} fill='#ffffff' />
            </div>
        );
    }
}
export default LoadingWidget;
