import React, { Component } from 'react';
import './Page.css';

class Page extends Component {
    render() {

        return (
            <div className="Page">
                <header className="PageHeader"><h1>{this.props.title}</h1></header>
                <div className="PageContent">
                    {this.props.children}
                </div>
            </div>
        );
    }
}
export default Page;
